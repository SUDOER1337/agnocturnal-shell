import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services.Keyboard

Item {
  id: root

  // ===== PUBLIC INTERFACE (CompositorService compatibility) =====

  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1
  property bool initialized: false

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  // ===== MANGOSERVICE-SPECIFIC PROPERTIES =====

  property string selectedMonitor: ""
  property string currentLayoutSymbol: ""

  // ===== INTERNAL STATE =====

  QtObject {
    id: internal

    // Latest monitor data from mmsg watch all-monitors
    property var lastMonitorData: null

    // Window-to-tag persistence: Map<UniqueID, TagID>
    property var windowTagMap: ({})

    // Window-to-output persistence: Map<UniqueID, OutputName>
    property var windowOutputMap: ({})

    // Toplevel-to-ID mapping: Map<ToplevelObject, UniqueID>
    property var toplevelIdMap: new Map()
    property int windowIdCounter: 0

    // Output name to index mapping for unique workspace IDs
    property var outputIndices: ({})
    property int outputCounter: 0

    // Monitor scales: Map<OutputName, scale>
    property var monitorScales: ({})

    // Window signature for change detection
    property string lastWindowSignature: ""

    // ===== REBUILD WORKSPACES FROM MMSG DATA =====

    function rebuildWorkspaces() {
      if (!internal.lastMonitorData || !internal.lastMonitorData.monitors) {
        Logger.w("MangoService", "rebuildWorkspaces: no monitor data available");
        return;
      }

      const monitors = internal.lastMonitorData.monitors;
      const workspaceList = [];

      for (let mi = 0; mi < monitors.length; mi++) {
        const mon = monitors[mi];
        const outputName = mon.name;

        // Assign stable index to output
        if (internal.outputIndices[outputName] === undefined) {
          internal.outputIndices[outputName] = internal.outputCounter++;
        }
        const outputIdx = internal.outputIndices[outputName];

        // Track selected monitor and layout
        if (mon.active) {
          root.selectedMonitor = outputName;
          root.currentLayoutSymbol = mon.layout_symbol || "";
        }

        // Store scale
        if (typeof mon.scale === "number") {
          internal.monitorScales[outputName] = mon.scale;
        }

        const tags = mon.tags || [];
        const activeTags = mon.active_tags || [];
        for (let ti = 0; ti < tags.length; ti++) {
          const tag = tags[ti];
          const tagId = tag.index; // mmsg tags are 1-based
          const uniqueId = outputIdx * 100 + tagId;

          workspaceList.push({
                               id: uniqueId,
                               idx: tagId,
                               name: tagId.toString(),
                               output: outputName,
                               isActive: activeTags.includes(tagId),
                               isFocused: tag.is_active && mon.active,
                               isUrgent: tag.is_urgent,
                               isOccupied: tag.client_count > 0
                             });
        }
      }

      // Sort by unique ID
      workspaceList.sort((a, b) => a.id - b.id);

      root.workspaces.clear();
      for (let k = 0; k < workspaceList.length; k++) {
        root.workspaces.append(workspaceList[k]);
      }

      root.workspaceChanged();
      if (workspaceList.length > 0) {
        Logger.d("MangoService", "Rebuilt", workspaceList.length, "workspaces from", monitors.length, "monitors");
      }
    }

    // ===== UPDATE WINDOWS =====

    function updateWindows() {
      if (!ToplevelManager.toplevels) {
        Logger.w("MangoService", "updateWindows: ToplevelManager.toplevels is null");
        return;
      }
      if (!internal.lastMonitorData || !internal.lastMonitorData.monitors) {
        Logger.w("MangoService", "updateWindows: no monitor data available");
        return;
      }

      const monitors = internal.lastMonitorData.monitors;
      const toplevels = ToplevelManager.toplevels.values;
      const windowList = [];
      let newFocusedIdx = -1;
      const currentWindows = new Set();

      // Build per-output state from mmsg data
      // Map<outputName, { title, appId, activeTagId }>
      const outputState = {};
      for (let mi = 0; mi < monitors.length; mi++) {
        const mon = monitors[mi];
        const outputName = mon.name;

        // Find first active tag
        let activeTagId = 1;
        const activeTags = mon.active_tags || [];
        if (activeTags.length > 0) {
          activeTagId = activeTags[0];
        }

        const ac = mon.active_client;
        outputState[outputName] = {
          title: ac ? (ac.title || "") : "",
          appId: ac ? (ac.appid || "") : "",
          activeTagId: activeTagId
        };

        // Ensure output index exists
        if (internal.outputIndices[outputName] === undefined) {
          internal.outputIndices[outputName] = internal.outputCounter++;
        }
      }

      for (let i = 0; i < toplevels.length; i++) {
        const toplevel = toplevels[i];
        if (!toplevel || toplevel.outliers) {
          continue;
        }

        const appId = toplevel.appId || toplevel.wayland?.appId || "";
        const title = toplevel.title || toplevel.wayland?.title || "";
        const isFocused = toplevel.activated;

        // Get or assign a stable ID
        let windowId;
        if (internal.toplevelIdMap.has(toplevel)) {
          windowId = internal.toplevelIdMap.get(toplevel);
        } else {
          windowId = `win-${internal.windowIdCounter++}`;
          internal.toplevelIdMap.set(toplevel, windowId);
        }

        currentWindows.add(windowId);

        // Determine output
        let outputName;

        // Priority 1: Focused window matched to mmsg output metadata
        if (isFocused && (title || appId)) {
          for (const oName in outputState) {
            const os = outputState[oName];
            if ((os.title || os.appId) && title === os.title && appId === os.appId) {
              outputName = oName;
              internal.windowOutputMap[windowId] = oName;
              break;
            }
          }
        }

        // Priority 2: Remembered output
        if (!outputName && internal.windowOutputMap[windowId]) {
          outputName = internal.windowOutputMap[windowId];
        }

        // Priority 3: toplevel.screens (wlr-foreign-toplevel visible screens)
        if (!outputName && toplevel.screens && toplevel.screens.length > 0) {
          outputName = toplevel.screens[0].name;
        }

        // Fallback: selected monitor
        if (!outputName) {
          outputName = root.selectedMonitor || "HDMI-A-1";
        }

        // Determine tag
        let tagId = null;

        const os = outputState[outputName];
        if (isFocused && os && !os.consumed && (os.title || os.appId) && title === os.title && appId === os.appId) {
          // Focused window: assign to the active tag from mmsg metadata
          tagId = os.activeTagId;
          internal.windowTagMap[windowId] = tagId;
          // Consume so a second toplevel with identical title+appId cannot also claim focus
          os.consumed = true;
        } else if (internal.windowTagMap[windowId] !== undefined) {
          // Previously seen window: use remembered tag
          tagId = internal.windowTagMap[windowId];
        }

        if (tagId === null) {
          // Can't determine the tag for unfocused windows until they gain focus.
          continue;
        }

        // Convert to unique workspace ID
        const outputIdx = internal.outputIndices[outputName];
        if (outputIdx === undefined) {
          Logger.e("MangoService", "No output index for", outputName);
          continue;
        }
        const workspaceId = outputIdx * 100 + tagId;

        windowList.push({
                          id: `${outputName}:${appId}:${title}:${i}`,
                          title: title,
                          appId: appId,
                          class: appId,
                          workspaceId: workspaceId,
                          isFocused: isFocused,
                          output: outputName,
                          handle: toplevel,
                          fullscreen: toplevel.fullscreen || false,
                          floating: toplevel.maximized === false && toplevel.fullscreen === false
                        });

        if (isFocused) {
          newFocusedIdx = windowList.length - 1;
        }
      }

      // Clean up stale window tracking
      if (Object.keys(internal.windowTagMap).length > toplevels.length + 20) {
        const newTagMap = {};
        const newOutputMap = {};
        for (const windowId of currentWindows) {
          if (internal.windowTagMap[windowId] !== undefined) {
            newTagMap[windowId] = internal.windowTagMap[windowId];
          }
          if (internal.windowOutputMap[windowId] !== undefined) {
            newOutputMap[windowId] = internal.windowOutputMap[windowId];
          }
        }
        internal.windowTagMap = newTagMap;
        internal.windowOutputMap = newOutputMap;
      }

      // Check if window list changed
      const signature = JSON.stringify(windowList.map(w => w.id + w.workspaceId + w.isFocused));
      if (signature !== internal.lastWindowSignature) {
        internal.lastWindowSignature = signature;
        root.windows = windowList;
        root.windowListChanged();
        Logger.d("MangoService", "Window list updated:", windowList.length, "windows,", toplevels.length, "toplevels");
      }

      if (newFocusedIdx !== root.focusedWindowIndex) {
        root.focusedWindowIndex = newFocusedIdx;
        root.activeWindowChanged();
      }
    }

    // ===== PROCESS MONITOR SCALES (forward to CompositorService) =====

    function processMonitorScales(monitors) {
      const scalesMap = {};
      for (let i = 0; i < monitors.length; i++) {
        const mon = monitors[i];
        if (mon.name && typeof mon.scale === "number") {
          internal.monitorScales[mon.name] = mon.scale;
          scalesMap[mon.name] = {
            name: mon.name,
            scale: mon.scale
          };
        }
      }

      if (typeof CompositorService !== "undefined" && CompositorService.onDisplayScalesUpdated) {
        CompositorService.onDisplayScalesUpdated(scalesMap);
      }

      root.displayScalesChanged();
    }
  }

  // ===== MMSG WATCH PROCESS (persistent stream) =====

  property QtObject _mmsgWatch: Process {
    id: mmsgWatch
    command: ["mmsg", "watch", "all-monitors"]
    running: root.initialized

    stdout: SplitParser {
      onRead: line => {
        const trimmed = line.trim();
        if (trimmed.length === 0)
          return;
        try {
          const data = JSON.parse(trimmed);
          if (data.monitors && Array.isArray(data.monitors)) {
            const prevData = internal.lastMonitorData;
            internal.lastMonitorData = data;
            internal.processMonitorScales(data.monitors);
            internal.rebuildWorkspaces();
            internal.updateWindows();
          }
        } catch (e) {
          Logger.e("MangoService", "Failed to parse mmsg watch output:", e);
        }
      }
    }

    onRunningChanged: {
      if (!running && root.initialized) {
        Logger.w("MangoService", "mmsg watch process exited, restarting in 1s");
        restartTimer.restart();
      }
    }
  }

  property QtObject _restartTimer: Timer {
    id: restartTimer
    interval: 1000
    onTriggered: {
      if (root.initialized && !mmsgWatch.running) {
        Logger.i("MangoService", "Restarting mmsg watch");
        mmsgWatch.running = true;
      }
    }
  }

  // ===== TOPLEVEL MANAGER CONNECTION =====

  property QtObject _toplevelConnection: Connections {
    target: ToplevelManager.toplevels
    enabled: ToplevelManager.toplevels !== null && ToplevelManager.toplevels !== undefined

    function onValuesChanged() {
      internal.updateWindows();
    }
  }

  // ===== PROCESSES =====

  // Keyboard layout polling - MangoWC doesn't send events for XKB-driven
  // layout switches (grp:win_space_toggle), so we poll mmsg periodically.
  property QtObject _kbLayoutPoll: Timer {
    id: kbLayoutPoll
    interval: 300
    running: false
    repeat: true

    property bool busy: false

    onTriggered: {
      if (busy)
        return;
      busy = true;
      kbLayoutQuery.running = true;
    }
  }

  property QtObject _kbLayoutQuery: Process {
    id: kbLayoutQuery
    command: ["mmsg", "get", "keyboardlayout"]

    property string buffer: ""

    stdout: SplitParser {
      onRead: line => {
        kbLayoutQuery.buffer += line + "\n";
      }
    }

    stderr: SplitParser {
      onRead: line => {
        if (line.trim().length > 0) {
          Logger.e("MangoService", "kbLayoutQuery stderr:", line.trim());
        }
      }
    }

    onExited: code => {
      if (code === 0) {
        try {
          var data = JSON.parse(kbLayoutQuery.buffer);
          var layout = String(data.layout ?? "").trim();
          if (layout.length > 0) {
            KeyboardLayoutService.setCurrentLayout(layout);
            Logger.d("MangoService", "Keyboard layout:", layout);
          }
        } catch (e) {
          Logger.e("MangoService", "Failed to parse keyboard layout JSON:", e);
        }
        kbLayoutQuery.buffer = "";
      } else {
        Logger.e("MangoService", "kbLayoutQuery exited with code", code);
      }
      kbLayoutPoll.busy = false;
    }
  }

  // ===== PUBLIC FUNCTIONS =====

  function initialize() {
    if (initialized) {
      return;
    }

    Logger.i("MangoService", "Initializing MangoWC compositor integration (mmsg IPC)");
    Logger.i("MangoService", "ToplevelManager.toplevels:", ToplevelManager.toplevels ? "available" : "null");
    Logger.i("MangoService", "Quickshell.screens count:", Quickshell.screens ? Quickshell.screens.length : 0);

    // Start mmsg watch (persistent stream)
    mmsgWatch.running = true;

    // Start keyboard layout polling
    kbLayoutPoll.running = true;

    initialized = true;
  }

  function queryDisplayScales() {
    // Scales are now updated via mmsg watch, but force a refresh
    const getProcess = ProcessFactory.createObject(root, {
      command: ["mmsg", "get", "all-monitors"]
    });
    getProcess.stdout = SplitParser.createObject(getProcess, {
      onRead: line => {
        try {
          const data = JSON.parse(line.trim());
          if (data.monitors) {
            internal.processMonitorScales(data.monitors);
          }
        } catch (e) {}
      }
    });
    getProcess.running = true;
    // Clean up after it finishes
    getProcess.onExited.connect(() => getProcess.destroy());
  }

  function switchToWorkspace(workspace) {
    const tagId = workspace.idx || workspace.id || 1;
    const outputName = workspace.output || root.selectedMonitor || "";

    let cmd = ["mmsg", "dispatch", "view," + tagId.toString()];
    if (outputName && Object.keys(internal.monitorScales).length > 1) {
      cmd.push("monitor," + outputName);
    }
    Quickshell.execDetached(cmd);
  }

  function focusWindow(window) {
    if (window && window.handle) {
      window.handle.activate();
    } else if (window.workspaceId) {
      switchToWorkspace({
                          id: window.workspaceId,
                          output: window.output
                        });
    }
  }

  function closeWindow(window) {
    if (window && window.handle) {
      window.handle.close();
    } else {
      Quickshell.execDetached(["mmsg", "dispatch", "killclient"]);
    }
  }

  function cycleKeyboardLayout() {
    Quickshell.execDetached(["mmsg", "dispatch", "switch_keyboard_layout"]);
  }

  function getFocusedScreen() {
    return null;
  }

  function spawn(command) {
    try {
      const cmd = ["mmsg", "dispatch", "spawn_shell," + command.join(" ")];
      Quickshell.execDetached(cmd);
    } catch (e) {
      Logger.e("MangoService", "Failed to spawn command:", e);
    }
  }
}
