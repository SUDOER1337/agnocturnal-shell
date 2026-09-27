import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Cards
import qs.Modules.MainScreen
import qs.Modules.Panels.Dashboard.Pages
import qs.Services.Compositor
import qs.Services.Media
import qs.Services.System
import qs.Services.UI
import qs.Widgets

SmartPanel {
  id: root

  // === CUSTOMIZATION GUIDE ===
  // This file controls the overall Dashboard layout and sizing.
  //
  // KEY SIZING PROPERTIES (see below for exact lines):
  // 1. Panel size           → Content-driven via contentPreferredWidth/Height
  //                           (panelContent); preferredWidth/preferredHeight below
  //                           are only the pre-content fallbacks
  // 2. Content margins      → contentLayout anchors.margins
  // 3. Sidebar-to-content gap → contentLayout / dashboardRow spacing
  // 4. Page header heights  → Lines ~248, ~297 (implicitHeight formulas)
  // 5. Sidebar sizing       → See Sidebar.qml (line ~50-60)
  // 6. Page content spacing → See individual Page files (MediaPlayerCard.qml, etc.)
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
    Dashboard,
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
  readonly property string dashboardPosition: Settings.data.dashboard.position

  readonly property bool hasBarOnScreen: {
    var monitors = Settings.data.bar.monitors || [];
    return monitors.length === 0 || monitors.includes(screen?.name);
  }

  readonly property bool shouldCenter: dashboardPosition === "close_to_bar_button" && !hasBarOnScreen

  panelAnchorHorizontalCenter: shouldCenter || (dashboardPosition !== "close_to_bar_button" && (dashboardPosition.endsWith("_center") || dashboardPosition === "center"))
  panelAnchorVerticalCenter: shouldCenter || dashboardPosition === "center"
  panelAnchorLeft: !shouldCenter && dashboardPosition !== "close_to_bar_button" && dashboardPosition.endsWith("_left")
  panelAnchorRight: !shouldCenter && dashboardPosition !== "close_to_bar_button" && dashboardPosition.endsWith("_right")
  panelAnchorBottom: !shouldCenter && dashboardPosition !== "close_to_bar_button" && dashboardPosition.startsWith("bottom_")
  panelAnchorTop: !shouldCenter && dashboardPosition !== "close_to_bar_button" && dashboardPosition.startsWith("top_")

  // === SIZING & SPACING - ADJUST HERE ===
  // The panel normally hugs its content (contentPreferredWidth/Height on
  // panelContent). These are only used until the content reports its size.
  preferredWidth: Math.round(640 * Style.uiScaleRatio)

  // Internal state
  property int _currentPage: 0

  // Page indices
  readonly property int pageQuickSettings: 0
  readonly property int pageSystem: 1

  onOpened: {
    MediaService.autoSwitchingPaused = true;
  }

  onClosed: {
    MediaService.autoSwitchingPaused = false;
  }

  // SettingsPanel-compatible API — redirects to standalone settings panel
  function openToTab(tab, subTab) {
    SettingsPanelService.openToTab(tab, subTab, root.screen);
  }

  // Keyboard handlers for SmartPanel integration
  function onTabPressed() {
    _currentPage = (_currentPage + 1) % 2;
  }

  function onBackTabPressed() {
    _currentPage = (_currentPage - 1 + 2) % 2;
  }

  function onEscapePressed() {
    close();
  }

  panelContent: Item {
    id: panelContent

    readonly property real contentPreferredWidth: contentLayout.implicitWidth + Style.margin2S
    // The Dashboard is capped so a tall column (big album art, a long month
    // grid, many shortcut rows) cannot stretch the window. Columns scroll
    // internally once the cap bites.
    readonly property real maxContentHeight: Math.round(360 * Style.uiScaleRatio)
    readonly property real contentPreferredHeight: Style.margin2S + Math.min(Math.max(contentLayout.implicitHeight, quickSettingsPage.contentImplicitHeight), panelContent.maxContentHeight)

    RowLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginS

      Sidebar {
        id: sidebar
        expanded: false
        currentIndex: root._currentPage

        onTabSelected: index => {
          root._currentPage = index;
        }

        onOpenSettingsRequested: {
          SettingsPanelService.openToTab(0, -1, root.screen);
        }
      }

      RowLayout {
        id: dashboardRow
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.marginS

        // Media player card — narrow full-height column beside the page area.
        // Scrolls because its artwork plus controls exceed the panel's cap.
        NScrollView {
          id: mediaScroll
          Layout.preferredWidth: mediaCard.implicitWidth
          Layout.fillHeight: true
          horizontalPolicy: ScrollBar.AlwaysOff
          reserveScrollbarSpace: false

          MediaPlayerCard {
            id: mediaCard
            screen: root.screen
            width: mediaScroll.availableWidth
          }
        }

        Item {
          id: pageArea
          implicitWidth: quickSettingsPage.contentImplicitWidth
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
              NumberAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
              }
            }
          }

          // System Page
          Rectangle {
            id: systemPageWrapper
            anchors.fill: parent
            color: "transparent"
            visible: root._currentPage === root.pageSystem
            opacity: root._currentPage === root.pageSystem ? 1 : 0

            Behavior on opacity {
              NumberAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
              }
            }

            ColumnLayout {
              id: systemColumn
              anchors.fill: parent
              // The outer layout already supplies the shared page inset.
              // Keep this margin only for the system page's own content.
              anchors.margins: Style.marginS
              spacing: Style.marginM

              // === SYSTEM PAGE HEADER HEIGHT ===
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
                id: systemPage
                Layout.fillWidth: true
                Layout.fillHeight: true
                screen: root.screen
              }
            }
          }
        }

        // Calendar column — fixed width so the month grid keeps its aspect
        NScrollView {
          id: calendarScroll
          Layout.preferredWidth: Math.round(300 * Style.uiScaleRatio)
          Layout.fillHeight: true
          horizontalPolicy: ScrollBar.AlwaysOff
          reserveScrollbarSpace: false

          CalendarMonthCard {
            width: calendarScroll.availableWidth
          }
        }

        // Notification history column — the same rows the Notification History
        // panel renders, kept always visible on the dashboard
        NotificationCard {
          id: notificationCard
          Layout.preferredWidth: Math.round(320 * Style.uiScaleRatio)
          Layout.fillHeight: true
        }
      }
    }
  }
}
