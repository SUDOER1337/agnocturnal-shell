import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.Dashboard
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  property ShellScreen screen

  // Entries come from Settings > Dashboard > Shortcuts. Each one is an object
  // holding the registry's PascalCase key under "id" plus that widget's own
  // settings (see CustomButtonSettings.saveSettings), so the entry doubles as
  // the loader's widgetProps. Core ids with no component in
  // DashboardWidgetRegistry are dropped here so a stale id in a hand-edited
  // config renders nothing instead of retrying forever in DashboardWidgetLoader.
  // Plugin ids always pass through: they register after this binding is first
  // evaluated and DashboardWidgetLoader already retries while waiting.
  readonly property var widgetEntries: {
    const shortcuts = Settings.data.dashboard.shortcuts;
    if (!shortcuts)
      return [];
    const entries = [];
    const seen = [];
    for (let s = 0; s < 2; s++) {
      const section = shortcuts[s === 0 ? "left" : "right"] || [];
      for (let i = 0; i < section.length; i++) {
        const entry = section[i];
        if (!entry)
          continue;
        let id = entry;
        if (typeof entry === "string")
          id = {
            "id": entry
          };
        if (!id.id || seen.indexOf(id.id) !== -1)
          continue;
        const known = id.id.startsWith("plugin:") || DashboardWidgetRegistry.hasWidget(id.id);
        if (known) {
          seen.push(id.id);
          entries.push(id);
        }
      }
    }
    return entries;
  }

  readonly property var widgetLabels: ({
                                         "AirplaneMode": "Airplane Mode",
                                         "Bluetooth": "Bluetooth",
                                         "CustomButton": "Custom",
                                         "DarkMode": "Dark Mode",
                                         "KeepAwake": "Keep Awake",
                                         "Network": "Network",
                                         "NightLight": "Night Light",
                                         "Notifications": "Notifications",
                                         "PowerProfile": "Power Profile",
                                         "WallpaperSelector": "Wallpaper",
                                         "WiFi": "Wi-Fi"
                                       })

  function labelForWidget(widgetId) {
    if (widgetId.startsWith("plugin:"))
      return widgetId.substring(7);
    if (root.widgetLabels[widgetId] !== undefined)
      return root.widgetLabels[widgetId];
    return widgetId;
  }

  color: "transparent"
  clip: true

  // === PANEL SIZING (drives the panel's content-driven width) ===
  readonly property real cellWidth: Math.round(120 * Style.uiScaleRatio)
  readonly property real contentImplicitHeight: quickLayout.implicitHeight
  readonly property real contentImplicitWidth: root.cellWidth * 2 + Style.marginM + Style.margin2S

  ColumnLayout {
    id: quickLayout
    anchors.fill: parent
    spacing: Style.marginM

    // === Shortcut Grid (2 columns) ===
    NBox {
      Layout.fillWidth: true
      Layout.fillHeight: true
      // Natural content height still drives the panel size; fillHeight lets the
      // card grow into the Dashboard's capped height, and the scroll view below
      // takes over once the rows no longer fit.
      implicitHeight: shortcutGrid.implicitHeight + Style.margin2S
      containerLevel: 1

      NScrollView {
        id: shortcutScroll
        anchors.fill: parent
        anchors.margins: Style.marginS
        horizontalPolicy: ScrollBar.AlwaysOff
        reserveScrollbarSpace: false

        GridLayout {
          id: shortcutGrid
          width: shortcutScroll.availableWidth
          columns: 2
          columnSpacing: Style.marginM
          rowSpacing: Style.marginM

          Repeater {
            model: root.widgetEntries

            delegate: Item {
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredWidth: root.cellWidth
              Layout.preferredHeight: Math.round(56 * Style.uiScaleRatio)

              DashboardWidgetLoader {
                id: widgetLoader
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                widgetId: parent.modelData.id
                widgetScreen: root.screen
                widgetProps: parent.modelData
              }

              NText {
                anchors.top: widgetLoader.bottom
                anchors.topMargin: Style.marginXXS
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: root.labelForWidget(parent.modelData.id)
                pointSize: Style.fontSizeXXS
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
              }
            }
          }
        }
      }
    }
  }
}
