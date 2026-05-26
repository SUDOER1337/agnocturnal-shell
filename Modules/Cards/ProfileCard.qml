import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Panels.ControlCenterV5
import qs.Modules.Panels.Settings
import qs.Services.System
import qs.Services.UI
import qs.Widgets

// Header card with avatar, user and quick actions
NBox {
  id: root

  property string uptimeText: "--"

  RowLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: Style.marginM
    spacing: Style.marginM

    // Initials avatar
    Rectangle {
      Layout.preferredWidth: Math.round(Style.baseWidgetSize * 1.25 * Style.uiScaleRatio)
      Layout.preferredHeight: Math.round(Style.baseWidgetSize * 1.25 * Style.uiScaleRatio)
      radius: Layout.preferredWidth / 2
      color: Color.mPrimaryContainer
      border.color: Color.mPrimary
      border.width: 2

      NText {
        anchors.centerIn: parent
        text: {
          var name = HostService.displayName || "U";
          var parts = name.trim().split(/\s+/);
          if (parts.length >= 2) return (parts[0][0] + parts[parts.length-1][0]).toUpperCase();
          return name.substring(0, 2).toUpperCase();
        }
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mOnPrimaryContainer
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: Style.marginXXS
      NText {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: HostService.displayName
        font.weight: Style.fontWeightBold
      }
      NText {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: "Uptime: {uptime}"
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }

    RowLayout {
      spacing: Style.marginS
      Layout.fillWidth: false
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      Item {
        Layout.fillWidth: true
      }
      NIconButton {
        icon: "settings"
        tooltipText: "Settings"
        onClicked: {
          // Better close the control center in case the settings open in a separate window
          PanelService.openedPanel?.close();

          var panel = PanelService.getPanel("controlCenterPanel", screen);
          panel.openToTab(ControlCenterV5Panel.Tab.General);
        }
      }

      NIconButton {
        icon: "power"
        tooltipText: "Session menu"
        onClicked: {
          PanelService.getPanel("sessionMenuPanel", screen)?.open();
          PanelService.getPanel("controlCenterPanel", screen)?.close();
        }
      }
    }
  }

  // ----------------------------------
  // Uptime
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: uptimeProcess.running = true
  }

  Process {
    id: uptimeProcess
    command: ["cat", "/proc/uptime"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        var uptimeSeconds = parseFloat(this.text.trim().split(' ')[0]);
        uptimeText = Time.formatVagueHumanReadableDuration(uptimeSeconds);
        uptimeProcess.running = false;
      }
    }
  }

  function updateSystemInfo() {
    uptimeProcess.running = true;
  }
}
