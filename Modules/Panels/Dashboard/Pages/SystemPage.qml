import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  property ShellScreen screen

  color: "transparent"

  Component.onCompleted: SystemStatService.registerComponent("ccv5-systempage")
  Component.onDestruction: SystemStatService.unregisterComponent("ccv5-systempage")

  readonly property string diskPath: {
    const sysMonWidget = BarService.lookupWidget("SystemMonitor");
    if (sysMonWidget && sysMonWidget.diskPath)
      return sysMonWidget.diskPath;
    return "/";
  }

  NScrollView {
    anchors.fill: parent
    verticalPolicy: ScrollBar.AsNeeded
    horizontalPolicy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: parent.width
      spacing: Style.marginM

      // CPU Card
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(90 * Style.uiScaleRatio)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginS
          anchors.bottomMargin: Math.round(Style.radiusM * 0.5)
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            NIcon {
              icon: "cpu-usage"
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
            }
            NText {
              text: `${Math.round(SystemStatService.cpuUsage)}% (${SystemStatService.cpuFreq.replace(/[^0-9.]/g, "")} GHz)`
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
              font.family: Settings.data.ui.fontFixed
            }
            NIcon {
              icon: "cpu-temperature"
              pointSize: Style.fontSizeXS
              color: Color.mSecondary
            }
            NText {
              text: `${Math.round(SystemStatService.cpuTemp)}°C`
              pointSize: Style.fontSizeXS
              color: Color.mSecondary
              font.family: Settings.data.ui.fontFixed
            }
            Item {
              Layout.fillWidth: true
            }
            NText {
              text: "CPU"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }

          NGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: SystemStatService.cpuHistory
            values2: SystemStatService.cpuTempHistory
            minValue: 0
            maxValue: 100
            minValue2: Math.max(SystemStatService.cpuTempHistoryMin - 5, 0)
            maxValue2: Math.max(SystemStatService.cpuTempHistoryMax + 5, 1)
            color: Color.mPrimary
            color2: Color.mSecondary
            strokeWidth: Math.max(1, Style.uiScaleRatio)
            fill: true
            fillOpacity: 0.15
            updateInterval: SystemStatService.cpuUsageIntervalMs
          }
        }
      }

      // Memory Card
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(90 * Style.uiScaleRatio)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginS
          anchors.bottomMargin: Math.round(Style.radiusM * 0.5)
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            NIcon {
              icon: "memory"
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
            }
            NText {
              text: `${Math.round(SystemStatService.memPercent)}% (${(SystemStatService.memGb).toFixed(1)} GiB)`
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
              font.family: Settings.data.ui.fontFixed
            }
            Item {
              Layout.fillWidth: true
            }
            NText {
              text: "Memory"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }

          NGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: SystemStatService.memHistory
            minValue: 0
            maxValue: 100
            color: Color.mPrimary
            strokeWidth: Math.max(1, Style.uiScaleRatio)
            fill: true
            fillOpacity: 0.15
            updateInterval: SystemStatService.memIntervalMs
          }
        }
      }

      // Network Card
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(90 * Style.uiScaleRatio)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginS
          anchors.bottomMargin: Math.round(Style.radiusM * 0.5)
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            NIcon {
              icon: "download-speed"
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
            }
            NText {
              text: SystemStatService.formatSpeed(SystemStatService.rxSpeed).replace(/([0-9.]+)([A-Za-z]+)/, "$1 $2") + "/s"
              pointSize: Style.fontSizeXS
              color: Color.mPrimary
              font.family: Settings.data.ui.fontFixed
            }
            NIcon {
              icon: "upload-speed"
              pointSize: Style.fontSizeXS
              color: Color.mSecondary
            }
            NText {
              text: SystemStatService.formatSpeed(SystemStatService.txSpeed).replace(/([0-9.]+)([A-Za-z]+)/, "$1 $2") + "/s"
              pointSize: Style.fontSizeXS
              color: Color.mSecondary
              font.family: Settings.data.ui.fontFixed
            }
            Item {
              Layout.fillWidth: true
            }
            NText {
              text: "Network"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }

          NGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: SystemStatService.rxSpeedHistory
            values2: SystemStatService.txSpeedHistory
            minValue: 0
            maxValue: SystemStatService.rxMaxSpeed
            minValue2: 0
            maxValue2: SystemStatService.txMaxSpeed
            color: Color.mPrimary
            color2: Color.mSecondary
            strokeWidth: Math.max(1, Style.uiScaleRatio)
            fill: true
            fillOpacity: 0.15
            updateInterval: SystemStatService.networkIntervalMs
            animateScale: true
          }
        }
      }

      // Detailed Stats
      NBox {
        Layout.fillWidth: true
        implicitHeight: detailsCol.implicitHeight + Style.margin2M

        ColumnLayout {
          id: detailsCol
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: SystemStatService.nproc > 0
            NIcon {
              icon: "cpu-usage"
              pointSize: Style.fontSizeM
              color: Color.mPrimary
            }
            NText {
              text: "Load:"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
            NText {
              text: `${SystemStatService.loadAvg1.toFixed(2)} / ${SystemStatService.loadAvg5.toFixed(2)} / ${SystemStatService.loadAvg15.toFixed(2)}`
              pointSize: Style.fontSizeXS
              color: Color.mOnSurface
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignRight
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: SystemStatService.gpuAvailable
            NIcon {
              icon: "gpu-temperature"
              pointSize: Style.fontSizeM
              color: Color.mPrimary
            }
            NText {
              text: "GPU:"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
            NText {
              text: `${Math.round(SystemStatService.gpuTemp)}°C`
              pointSize: Style.fontSizeXS
              color: Color.mOnSurface
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignRight
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            NIcon {
              icon: "storage"
              pointSize: Style.fontSizeM
              color: Color.mPrimary
            }
            NText {
              text: "Disk:"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
            NText {
              text: {
                const usedGb = SystemStatService.diskUsedGb[diskPath] || 0;
                const sizeGb = SystemStatService.diskSizeGb[diskPath] || 0;
                const percent = SystemStatService.diskPercents[diskPath] || 0;
                return `${percent}% (${usedGb.toFixed(1)} / ${sizeGb.toFixed(1)} GB)`;
              }
              pointSize: Style.fontSizeXS
              color: Color.mOnSurface
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignRight
              elide: Text.ElideMiddle
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: SystemStatService.swapTotalGb > 0
            NIcon {
              icon: "exchange"
              pointSize: Style.fontSizeM
              color: Color.mPrimary
            }
            NText {
              text: "Swap:"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
            NText {
              text: `${(SystemStatService.swapGb).toFixed(1)} / ${(SystemStatService.swapTotalGb).toFixed(1)} GiB`
              pointSize: Style.fontSizeXS
              color: Color.mOnSurface
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
