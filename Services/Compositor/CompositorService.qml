pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Control
import qs.Services.UI

Singleton {
  id: root

  property bool isHyprland: false
  property bool isNiri: false
  property bool isSway: false
  property bool isMango: false
  property bool isLabwc: false
  property bool isExtWorkspace: false
  property bool isScroll: false

  property ListModel workspaces: ListModel {}
  property ListModel windows: ListModel {}
  property int focusedWindowIndex: -1

  property var displayScales: ({})
  property bool displayScalesLoaded: false
  property bool overviewActive: false
  property bool globalWorkspaces: false

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged

  property var backend: null

  Component.onCompleted: {
    Qt.callLater(() => {
      if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
        loadDisplayScalesFromState();
      }
    });
    detectCompositor();
  }

  Connections {
    target: typeof ShellState !== 'undefined' ? ShellState : null
    function onIsLoadedChanged() {
      if (ShellState.isLoaded) {
        loadDisplayScalesFromState();
      }
    }
  }

  function detectCompositor() {
    const niriSocket = Quickshell.env("NIRI_SOCKET");
    const currentDesktop = Quickshell.env("XDG_CURRENT_DESKTOP");

    if (currentDesktop && currentDesktop.toLowerCase().includes("mango")) {
      isMango = true;
      backendLoader.sourceComponent = mangoComponent;
    } else if (niriSocket && niriSocket.length > 0) {
      isNiri = true;
      backendLoader.sourceComponent = niriComponent;
    } else {
      isNiri = true;
      backendLoader.sourceComponent = niriComponent;
      Logger.i("CompositorService", "No compositor env detected, defaulting to Niri backend");
    }
  }

  Loader {
    id: backendLoader
    onLoaded: {
      if (item) {
        root.backend = item;
        setupBackendConnections();
        backend.initialize();
      }
    }
  }

  function loadDisplayScalesFromState() {
    try {
      const cached = ShellState.getDisplay();
      if (cached && Object.keys(cached).length > 0) {
        displayScales = cached;
        displayScalesLoaded = true;
        Logger.d("CompositorService", "Loaded display scales from ShellState");
      } else {
        displayScalesLoaded = true;
      }
    } catch (error) {
      Logger.e("CompositorService", "Failed to load display scales:", error);
      displayScalesLoaded = true;
    }
  }

  Component {
    id: niriComponent
    NiriService {}
  }

  Component {
    id: mangoComponent
    MangoService {}
  }

  function setupBackendConnections() {
    if (!backend)
      return;

    backend.workspaceChanged.connect(() => {
      syncWorkspaces();
      workspaceChanged();
    });

    backend.activeWindowChanged.connect(() => {
      syncFocusedWindow();
      activeWindowChanged();
    });

    backend.windowListChanged.connect(() => {
      syncWindows();
    });

    backend.focusedWindowIndexChanged.connect(() => {
      focusedWindowIndex = backend.focusedWindowIndex;
    });

    if (backend.overviewActiveChanged) {
      backend.overviewActiveChanged.connect(() => {
        overviewActive = backend.overviewActive;
      });
    }

    syncWorkspaces();
    syncWindows();
    focusedWindowIndex = backend.focusedWindowIndex;
    if (backend.overviewActive !== undefined)
      overviewActive = backend.overviewActive;
    if (backend.globalWorkspaces !== undefined)
      globalWorkspaces = backend.globalWorkspaces;
  }

  function syncWorkspaces() {
    workspaces.clear();
    const ws = backend.workspaces;
    for (var i = 0; i < ws.count; i++) {
      workspaces.append(ws.get(i));
    }
    workspacesChanged();
  }

  function syncWindows() {
    windows.clear();
    const ws = backend.windows;
    for (var i = 0; i < ws.length; i++) {
      windows.append(ws[i]);
    }
    windowListChanged();
  }

  function syncFocusedWindow() {
    const newIndex = backend.focusedWindowIndex;
    for (var i = 0; i < windows.count && i < backend.windows.length; i++) {
      const backendFocused = backend.windows[i].isFocused;
      if (windows.get(i).isFocused !== backendFocused) {
        windows.setProperty(i, "isFocused", backendFocused);
      }
    }
    focusedWindowIndex = newIndex;
  }

  function updateDisplayScales() {
    if (!backend || !backend.queryDisplayScales) {
      Logger.w("CompositorService", "Backend does not support display scale queries");
      return;
    }
    backend.queryDisplayScales();
  }

  function onDisplayScalesUpdated(scales) {
    displayScales = scales;
    saveDisplayScalesToCache();
    Logger.d("CompositorService", "Display scales updated");
  }

  function saveDisplayScalesToCache() {
    try {
      ShellState.setDisplay(displayScales);
    } catch (error) {
      Logger.e("CompositorService", "Failed to save display scales:", error);
    }
  }

  function getDisplayScale(displayName) {
    if (!displayName || !displayScales[displayName])
      return 1.0;
    return displayScales[displayName].scale || 1.0;
  }

  function getDisplayInfo(displayName) {
    if (!displayName || !displayScales[displayName])
      return null;
    return displayScales[displayName];
  }

  function getFocusedWindow() {
    if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.count) {
      return windows.get(focusedWindowIndex);
    }
    return null;
  }

  function getFocusedScreen() {
    if (backend && backend.getFocusedScreen)
      return backend.getFocusedScreen();
    return null;
  }

  function getFocusedWindowTitle() {
    if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.count) {
      var title = windows.get(focusedWindowIndex).title;
      if (title !== undefined)
        title = title.replace(/(\r\n|\n|\r)/g, "");
      return title || "";
    }
    return "";
  }

  function getCleanAppName(appId, fallbackTitle) {
    var name = (appId || "").split(".").pop() || fallbackTitle || "Unknown";
    return name.charAt(0).toUpperCase() + name.slice(1);
  }

  function getWindowsForWorkspace(workspaceId) {
    var windowsInWs = [];
    for (var i = 0; i < windows.count; i++) {
      var window = windows.get(i);
      if (window.workspaceId === workspaceId) {
        windowsInWs.push({
                           id: window.id,
                           title: window.title,
                           appId: window.appId,
                           isFocused: window.isFocused,
                           workspaceId: window.workspaceId,
                           handle: window.handle
                         });
      }
    }
    return windowsInWs;
  }

  function switchToWorkspace(workspace) {
    if (backend && backend.switchToWorkspace) {
      backend.switchToWorkspace(workspace);
    } else {
      Logger.w("Compositor", "No backend available for workspace switching");
    }
  }

  function scrollWorkspaceContent(direction) {
    if (backend && backend.scrollWorkspaceContent) {
      backend.scrollWorkspaceContent(direction);
    }
  }

  function getCurrentWorkspace() {
    for (var i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i);
      if (ws.isFocused)
        return ws;
    }
    return null;
  }

  function getActiveWorkspaces() {
    const activeWorkspaces = [];
    for (var i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i);
      if (ws.isActive)
        activeWorkspaces.push(ws);
    }
    return activeWorkspaces;
  }

  function focusWindow(window) {
    if (backend && backend.focusWindow) {
      backend.focusWindow(window);
    } else {
      Logger.w("Compositor", "No backend available for window focus");
    }
  }

  function closeWindow(window) {
    if (backend && backend.closeWindow) {
      backend.closeWindow(window);
    } else {
      Logger.w("Compositor", "No backend available for window closing");
    }
  }

  function spawn(command) {
    const cmdArray = Array.isArray(command) ? command : (command && typeof command === "object" && command.length !== undefined) ? Array.from(command) : [command];

    Logger.d("CompositorService", "Spawning: " + cmdArray.join(" "));
    if (backend && backend.spawn) {
      backend.spawn(cmdArray);
    } else {
      try {
        Quickshell.execDetached(cmdArray);
      } catch (e) {
        Logger.e("CompositorService", "Failed to execute detached:", e);
      }
    }
  }

  function getCustomCommand(action) {
    const powerOptions = Settings.data.sessionMenu.powerOptions || [];
    for (let i = 0; i < powerOptions.length; i++) {
      const option = powerOptions[i];
      if (option.action === action && option.enabled && option.command && option.command.trim() !== "") {
        return option.command.trim();
      }
    }
    return "";
  }

  function executeSessionAction(action, defaultCommand) {
    const customCommand = getCustomCommand(action);
    if (customCommand) {
      Logger.i("Compositor", "Executing custom command for action: " + action + " Command: " + customCommand);
      Quickshell.execDetached(["sh", "-c", customCommand]);
      return true;
    }
    return false;
  }

  function logout() {
    Logger.i("Compositor", "Logout requested");
    if (executeSessionAction("logout"))
      return;
    if (backend && backend.logout) {
      backend.logout();
    } else {
      Logger.w("Compositor", "No backend available for logout");
    }
  }

  function shutdown() {
    Logger.i("Compositor", "Shutdown requested");
    if (executeSessionAction("shutdown"))
      return;
    HooksService.executeSessionHook("shutdown", () => {
      Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"]);
    });
  }

  function reboot() {
    Logger.i("Compositor", "Reboot requested");
    if (executeSessionAction("reboot"))
      return;
    HooksService.executeSessionHook("reboot", () => {
      Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"]);
    });
  }

  function userspaceReboot() {
    Logger.i("Compositor", "Userspace reboot requested");
    if (executeSessionAction("userspaceReboot"))
      return;
    HooksService.executeSessionHook("userspaceReboot", () => {
      Quickshell.execDetached(["sh", "-c", "systemctl soft-reboot"]);
    });
  }

  function rebootToUefi() {
    Logger.i("Compositor", "Reboot to UEFI firmware requested");
    if (executeSessionAction("rebootToUefi"))
      return;
    HooksService.executeSessionHook("rebootToUefi", () => {
      Quickshell.execDetached(["sh", "-c", "systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"]);
    });
  }

  function turnOffMonitors() {
    Logger.i("Compositor", "Turn off monitors requested");
    if (backend && backend.turnOffMonitors) {
      backend.turnOffMonitors();
    } else {
      Logger.w("Compositor", "No backend available for turnOffMonitors");
    }
  }

  function turnOnMonitors() {
    Logger.i("Compositor", "Turn on monitors requested");
    if (backend && backend.turnOnMonitors) {
      backend.turnOnMonitors();
    } else {
      Logger.w("Compositor", "No backend available for turnOnMonitors");
    }
  }

  function suspend() {
    Logger.i("Compositor", "Suspend requested");
    if (executeSessionAction("suspend"))
      return;
    Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]);
  }

  function lock() {
    Logger.i("Compositor", "LockScreen requested");
    if (executeSessionAction("lock"))
      return;
    if (PanelService && PanelService.lockScreen) {
      PanelService.lockScreen.active = true;
    }
  }

  function hibernate() {
    Logger.i("Compositor", "Hibernate requested");
    if (executeSessionAction("hibernate"))
      return;
    Quickshell.execDetached(["sh", "-c", "systemctl hibernate || loginctl hibernate"]);
  }

  function cycleKeyboardLayout() {
    if (backend && backend.cycleKeyboardLayout) {
      backend.cycleKeyboardLayout();
    }
  }

  property int lockAndSuspendCheckCount: 0

  function lockAndSuspend() {
    Logger.i("Compositor", "Lock and suspend requested");
    if (executeSessionAction("lock")) {
      suspend();
      return;
    }
    if (PanelService && PanelService.lockScreen && PanelService.lockScreen.active) {
      Logger.i("Compositor", "Screen already locked, suspending");
      suspend();
      return;
    }
    try {
      if (PanelService && PanelService.lockScreen) {
        PanelService.lockScreen.active = true;
        lockAndSuspendCheckCount = 0;
        lockAndSuspendTimer.start();
      } else {
        Logger.w("Compositor", "Lock screen not available, suspending without lock");
        suspend();
      }
    } catch (e) {
      Logger.w("Compositor", "Failed to activate lock screen before suspend: " + e);
      suspend();
    }
  }

  Timer {
    id: lockAndSuspendTimer
    interval: 100
    repeat: true
    running: false
    onTriggered: {
      lockAndSuspendCheckCount++;
      if (PanelService && PanelService.lockScreen && PanelService.lockScreen.active) {
        if (PanelService.lockScreen.item) {
          Logger.i("Compositor", "Lock screen confirmed active, suspending");
          stop();
          lockAndSuspendCheckCount = 0;
          suspend();
        } else {
          if (lockAndSuspendCheckCount > 20) {
            Logger.w("Compositor", "Lock screen active but component not loaded, suspending anyway");
            stop();
            lockAndSuspendCheckCount = 0;
            suspend();
          }
        }
      } else {
        if (lockAndSuspendCheckCount > 30) {
          Logger.w("Compositor", "Lock screen failed to activate, suspending anyway");
          stop();
          lockAndSuspendCheckCount = 0;
          suspend();
        }
      }
    }
  }
}
