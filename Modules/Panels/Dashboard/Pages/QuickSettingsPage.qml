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

  function labelForWidget(widgetId) {
    const labels = {
      "network": "Network",
      "bluetooth": "Bluetooth",
      "night-light": "Night Light",
      "dark-mode": "Dark Mode",
      "notifications": "Notifications",
      "keep-awake": "Keep Awake",
      "power-profile": "Power Profile",
      "airplane-mode": "Airplane Mode"
    };
    return labels[widgetId] || widgetId;
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
      Layout.alignment: Qt.AlignVCenter
      implicitHeight: shortcutGrid.implicitHeight + Style.margin2S
      containerLevel: 1

      GridLayout {
        id: shortcutGrid
        anchors.fill: parent
        anchors.margins: Style.marginS
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginM

        Repeater {
          model: ["network", "bluetooth", "night-light", "dark-mode", "notifications", "keep-awake", "power-profile", "airplane-mode"]

          delegate: Item {
            required property string modelData
            Layout.fillWidth: true
            Layout.preferredWidth: root.cellWidth
            Layout.preferredHeight: Math.round(56 * Style.uiScaleRatio)

            DashboardWidgetLoader {
              id: widgetLoader
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              widgetId: parent.modelData
              widgetScreen: root.screen
              widgetProps: ({})
            }

            NText {
              anchors.top: widgetLoader.bottom
              anchors.topMargin: Style.marginXXS
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              text: root.labelForWidget(parent.modelData)
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
