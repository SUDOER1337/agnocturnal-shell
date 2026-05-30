import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.ControlCenter
import qs.Services.Location
import qs.Services.Media
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  property ShellScreen screen
  signal openSettingsRequested

  color: "transparent"
  clip: true

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginS
    spacing: Style.marginM

    // === Top Row: Date/Time + Weather ===
    NBox {
      Layout.fillWidth: true
      implicitHeight: topRow.implicitHeight + Style.margin2M

      RowLayout {
        id: topRow
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        ColumnLayout {
          spacing: 0

          NText {
            id: timeText
            text: new Date().toLocaleTimeString(Locale.ShortFormat)
            pointSize: Style.fontSizeXXL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            id: dateText
            text: new Date().toLocaleDateString(Locale.LongFormat)
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }

          Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: {
              timeText.text = new Date().toLocaleTimeString(Locale.ShortFormat);
              dateText.text = new Date().toLocaleDateString(Locale.LongFormat);
            }
          }
        }

        Item {
          Layout.fillWidth: true
        }

        // Weather (via LocationService — matches WeatherCard pattern)
        Rectangle {
          readonly property bool weatherReady: Settings.data.location.weatherEnabled && LocationService.data.weather !== null

          visible: weatherReady
          implicitWidth: weatherRow.implicitWidth + Style.marginM
          implicitHeight: weatherRow.implicitHeight + Style.marginS
          radius: Style.radiusS
          color: Color.mSurfaceVariant

          RowLayout {
            id: weatherRow
            anchors.centerIn: parent
            spacing: Style.marginXS

            NIcon {
              icon: weatherReady ? LocationService.weatherSymbolFromCode(LocationService.data.weather.current_weather.weathercode) : "weather-cloud-sun"
              pointSize: Style.fontSizeXL
              color: Color.mOnSurfaceVariant
            }

            ColumnLayout {
              spacing: 0

              NText {
                readonly property real rawTemp: weatherReady ? LocationService.data.weather.current_weather.temperature : 0
                text: weatherReady ? `${Math.round(rawTemp)}°` : "--°"
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }
            }
          }
        }
      }
    }

    // === Shortcut Grid (2 columns) ===
    NBox {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "transparent"

      GridLayout {
        id: shortcutGrid
        anchors.fill: parent
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginM

        ControlCenterWidgetLoader {
          widgetId: "network"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "bluetooth"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "night-light"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "dark-mode"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "notifications"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "keep-awake"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "power-profile"
          widgetScreen: root.screen
          widgetProps: ({})
        }

        ControlCenterWidgetLoader {
          widgetId: "airplane-mode"
          widgetScreen: root.screen
          widgetProps: ({})
        }
      }
    }

    // === Bottom Row: Media Mini + System Mini + Settings ===
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      // Media Mini Card
      NBox {
        Layout.fillWidth: true
        implicitHeight: mediaMiniRow.implicitHeight + Style.marginM
        visible: MediaService.currentPlayer !== null

        RowLayout {
          id: mediaMiniRow
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginS

          NImageRounded {
            implicitWidth: Math.round(32 * Style.uiScaleRatio)
            implicitHeight: Math.round(32 * Style.uiScaleRatio)
            radius: Style.radiusS
            imagePath: MediaService.trackArtUrl
            imageFillMode: Image.PreserveAspectCrop
            fallbackIcon: "disc"
            fallbackIconSize: Style.fontSizeL
            borderWidth: 0
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            NText {
              text: MediaService.trackTitle || "No Media"
              pointSize: Style.fontSizeXS
              font.weight: Style.fontWeightSemiBold
              color: Color.mOnSurface
              elide: Text.ElideRight
              Layout.fillWidth: true
              maximumLineCount: 1
            }

            NText {
              text: MediaService.trackArtist || ""
              pointSize: Style.fontSizeXXS
              color: Color.mOnSurfaceVariant
              elide: Text.ElideRight
              Layout.fillWidth: true
              maximumLineCount: 1
              visible: text !== ""
            }
          }

          NIconButton {
            icon: MediaService.isPlaying ? "media-pause" : "media-play"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: MediaService.playPause()
          }
        }
      }

      // System Mini Card
      NBox {
        Layout.fillWidth: true
        implicitHeight: sysMiniRow.implicitHeight + Style.marginM

        RowLayout {
          id: sysMiniRow
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginS

          ColumnLayout {
            spacing: 0

            NText {
              text: `CPU ${Math.round(SystemStatService.cpuUsage)}%`
              pointSize: Style.fontSizeXS
              font.weight: Style.fontWeightSemiBold
              color: Color.mOnSurface
            }

            NText {
              text: `RAM ${Math.round(SystemStatService.memPercent)}%`
              pointSize: Style.fontSizeXXS
              color: Color.mOnSurfaceVariant
            }
          }
        }
      }
    }

    // Open Settings button
    NButton {
      Layout.fillWidth: true
      text: "Open Settings"
      onClicked: root.openSettingsRequested()
    }
  }
}
