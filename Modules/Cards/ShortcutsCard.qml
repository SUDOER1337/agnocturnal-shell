import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.Dashboard
import qs.Widgets

RowLayout {
  Layout.fillWidth: true
  spacing: Style.marginL

  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: root.shortcutsHeight
    visible: Settings.data.dashboard.shortcuts.left.length > 0

    RowLayout {
      id: leftContent
      anchors.fill: parent
      spacing: Style.marginS

      Item {
        Layout.fillWidth: true
      }

      Repeater {
        model: Settings.data.dashboard.shortcuts.left
        delegate: DashboardWidgetLoader {
          required property var modelData
          required property int index

          Layout.fillWidth: false
          widgetId: (modelData.id !== undefined ? modelData.id : "")
          widgetScreen: root.screen
          widgetProps: {
            "widgetId": modelData.id,
            "section": "quickSettings",
            "sectionWidgetIndex": index,
            "sectionWidgetsCount": Settings.data.dashboard.shortcuts.left.length,
            "widgetSettings": modelData
          }
          Layout.alignment: Qt.AlignVCenter
        }
      }

      Item {
        Layout.fillWidth: true
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: root.shortcutsHeight
    visible: Settings.data.dashboard.shortcuts.right.length > 0

    RowLayout {
      id: rightContent
      anchors.fill: parent
      spacing: Style.marginS

      Item {
        Layout.fillWidth: true
      }

      Repeater {
        model: Settings.data.dashboard.shortcuts.right
        delegate: DashboardWidgetLoader {
          required property var modelData
          required property int index

          Layout.fillWidth: false
          widgetId: (modelData.id !== undefined ? modelData.id : "")
          widgetScreen: root.screen
          widgetProps: {
            "widgetId": modelData.id,
            "section": "quickSettings",
            "sectionWidgetIndex": index,
            "sectionWidgetsCount": Settings.data.dashboard.shortcuts.right.length,
            "widgetSettings": modelData
          }
          Layout.alignment: Qt.AlignVCenter
        }
      }

      Item {
        Layout.fillWidth: true
      }
    }
  }
}
