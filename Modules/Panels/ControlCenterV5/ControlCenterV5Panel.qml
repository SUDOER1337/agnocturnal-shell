import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.MainScreen
import qs.Modules.Panels.ControlCenterV5.Pages
import qs.Services.Compositor
import qs.Services.Media
import qs.Services.System
import qs.Services.UI
import qs.Widgets

SmartPanel {
  id: root

  // === CUSTOMIZATION GUIDE ===
  // This file controls the overall ControlCenter V5 layout and sizing.
  // 
  // KEY SIZING PROPERTIES (see below for exact lines):
  // 1. Panel width          → Line ~63  (preferredWidth: 480px)
  // 2. Content margins      → Line ~187 (anchors.margins)
  // 3. Sidebar-to-content gap → Line ~188 (spacing)
  // 4. Page header heights  → Lines ~248, ~297 (implicitHeight formulas)
  // 5. Sidebar sizing       → See Sidebar.qml (line ~50-60)
  // 6. Page content spacing → See individual Page files (MediaPage.qml, etc.)
  //
  // ADJUSTMENT SCALE REFERENCE:
  // - Style.marginXS = ~4px, marginS = ~8px, marginM = ~12px, marginL = ~16px
  // - Most sizes scale with Style.uiScaleRatio (UI zoom setting)
  //
  // === Tab Enum (matches SettingsPanel.Tab for backward compatibility) ===
  enum Tab {
    About,
    Audio,
    Bar,
    ColorScheme,
    LockScreen,
    ControlCenter,
    DesktopWidgets,
    OSD,
    Display,
    Dock,
    General,
    Hooks,
    Idle,
    Launcher,
    Location,
    Connections,
    Notifications,
    Plugins,
    SessionMenu,
    System,
    UserInterface,
    Wallpaper
  }

  // Positioning
  readonly property string controlCenterPosition: Settings.data.controlCenter.position

  readonly property bool hasBarOnScreen: {
    var monitors = Settings.data.bar.monitors || [];
    return monitors.length === 0 || monitors.includes(screen?.name);
  }

  readonly property bool shouldCenter: controlCenterPosition === "close_to_bar_button" && !hasBarOnScreen

  panelAnchorHorizontalCenter: shouldCenter || (controlCenterPosition !== "close_to_bar_button" && (controlCenterPosition.endsWith("_center") || controlCenterPosition === "center"))
  panelAnchorVerticalCenter: shouldCenter || controlCenterPosition === "center"
  panelAnchorLeft: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_left")
  panelAnchorRight: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_right")
  panelAnchorBottom: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("bottom_")
  panelAnchorTop: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("top_")

  // === SIZING & SPACING - ADJUST HERE ===
  // Main panel width (default 480px, scales with UI zoom)
  // Adjust the multiplier (480) to change panel width: smaller = narrower, larger = wider
  preferredWidth: Math.round(480 * Style.uiScaleRatio)

  // Settings compatibility
  property int requestedTab: ControlCenterV5Panel.Tab.General
  property int requestedSubTab: -1
  property var requestedEntry: null

  // Internal state
  property int _currentPage: 0
  property var _settingsPage: null
  property bool _pendingSubTab: false

  // Page indices
  readonly property int pageQuickSettings: 0
  readonly property int pageMedia: 1
  readonly property int pageSystem: 2
  readonly property int pageSettings: 3

  onOpened: {
    MediaService.autoSwitchingPaused = true;
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.initialize();
    }
  }

  onClosed: {
    MediaService.autoSwitchingPaused = false;
  }

  // SettingsPanel-compatible API
  function openToTab(tab, subTab) {
    requestedTab = tab !== undefined ? tab : ControlCenterV5Panel.Tab.General;
    requestedSubTab = subTab !== undefined ? subTab : -1;
    _currentPage = pageSettings;
    if (_settingsPage) {
      _settingsPage.requestedTab = requestedTab;
      if (requestedSubTab >= 0) {
        _settingsPage._pendingSubTab = requestedSubTab;
      }
      Qt.callLater(() => _settingsPage.initialize());
    }
    if (!isPanelOpen) {
      open();
    }
  }

  function navigateToResult(entry) {
    requestedEntry = entry;
    _currentPage = pageSettings;
    if (_settingsPage) {
      _settingsPage.requestedEntry = entry;
      _settingsPage.initialize();
    }
  }

  // Keyboard handlers for SmartPanel integration
  function onTabPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.selectNextTab();
    } else {
      _currentPage = (_currentPage + 1) % 4;
    }
  }

  function onBackTabPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.selectPreviousTab();
    } else {
      _currentPage = (_currentPage - 1 + 4) % 4;
    }
  }

  function onUpPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.scrollUp();
    }
  }

  function onDownPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.scrollDown();
    }
  }

  function onPageUpPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.scrollPageUp();
    }
  }

  function onPageDownPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.scrollPageDown();
    }
  }

  function onCtrlJPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.scrollDown();
    }
  }

  function onCtrlKPressed() {
    if (_currentPage === pageSettings && _settingsPage) {
      _settingsPage.scrollUp();
    }
  }

  function onEscapePressed() {
    if (_settingsPage && _settingsPage.searchText.trim() !== "") {
      _settingsPage.searchText = "";
      return;
    }
    close();
  }

  panelContent: Item {
    id: panelContent

    // === CONTENT LAYOUT - SPACING & MARGINS ===
    // Adjust margins and spacing to control internal padding and gaps
    // margins: padding around the entire content (left/right/top/bottom)
    // spacing: gap between Sidebar and content area
    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS        // ← Adjust for more/less padding around content
      spacing: Style.marginS                 // ← Adjust gap between sidebar and pages

      Sidebar {
        id: sidebar
        expanded: true
        currentIndex: root._currentPage

        onTabSelected: index => {
          root._currentPage = index;
          if (index === root.pageSettings && root._settingsPage) {
            if (root.requestedEntry) {
              root._settingsPage.requestedEntry = root.requestedEntry;
              root.requestedEntry = null;
            }
            Qt.callLater(() => root._settingsPage.initialize());
          }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Quick Settings Page
        QuickSettingsPage {
          id: quickSettingsPage
          anchors.fill: parent
          screen: root.screen
          visible: root._currentPage === root.pageQuickSettings
          opacity: root._currentPage === root.pageQuickSettings ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
          }

          onOpenSettingsRequested: {
            root._currentPage = root.pageSettings;
            if (root._settingsPage) {
              Qt.callLater(() => root._settingsPage.initialize());
            }
          }
        }

        // Media Page
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          visible: root._currentPage === root.pageMedia
          opacity: root._currentPage === root.pageMedia ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
          }

           ColumnLayout {
             anchors.fill: parent
             anchors.margins: Style.marginS
             spacing: Style.marginM

             // === MEDIA PAGE HEADER HEIGHT ===
             // implicitHeight: auto-calculated from content + padding
             // Adjust Style.margin2M to change header padding
             NBox {
               Layout.fillWidth: true
               implicitHeight: mediaHeader.implicitHeight + Style.margin2M

              RowLayout {
                id: mediaHeader
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                  icon: "music"
                  pointSize: Style.fontSizeL
                  color: Color.mPrimary
                }

                NText {
                  text: "Media"
                  font.weight: Style.fontWeightBold
                  pointSize: Style.fontSizeL
                  color: Color.mOnSurface
                  Layout.fillWidth: true
                }
              }
            }

            MediaPage {
              Layout.fillWidth: true
              Layout.fillHeight: true
            }
          }
        }

        // System Page
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          visible: root._currentPage === root.pageSystem
          opacity: root._currentPage === root.pageSystem ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
          }

           ColumnLayout {
             anchors.fill: parent
             anchors.margins: Style.marginS
             spacing: Style.marginM

             // === SYSTEM PAGE HEADER HEIGHT ===
             // implicitHeight: auto-calculated from content + padding
             // Adjust Style.margin2M to change header padding
             NBox {
               Layout.fillWidth: true
               implicitHeight: sysHeader.implicitHeight + Style.margin2M

              RowLayout {
                id: sysHeader
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                  icon: "device-analytics"
                  pointSize: Style.fontSizeL
                  color: Color.mPrimary
                }

                NText {
                  text: "System"
                  font.weight: Style.fontWeightBold
                  pointSize: Style.fontSizeL
                  color: Color.mOnSurface
                  Layout.fillWidth: true
                }
              }
            }

            SystemPage {
              Layout.fillWidth: true
              Layout.fillHeight: true
              screen: root.screen
            }
          }
        }

        // Settings Page
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          visible: root._currentPage === root.pageSettings
          opacity: root._currentPage === root.pageSettings ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
          }

          SettingsPage {
            id: settingsPage
            anchors.fill: parent
            screen: root.screen

            Component.onCompleted: {
              root._settingsPage = settingsPage;
              if (root.requestedEntry) {
                settingsPage.requestedEntry = root.requestedEntry;
                root.requestedEntry = null;
              }
            }

            onCloseRequested: root.close()
          }
        }
      }
    }
  }
}
