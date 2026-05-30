import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Media
import qs.Services.UI
import qs.Widgets
import qs.Widgets.AudioSpectrum

Rectangle {
  id: root

  color: "transparent"

  readonly property string visualizerType: "none"
  readonly property bool showArtistFirst: true
  readonly property bool showAlbumArt: true
  readonly property bool showVisualizer: false
  readonly property bool compactMode: false
  readonly property string scrollingMode: "hover"
  readonly property bool isSideBySide: false
  readonly property bool needsSpectrum: showVisualizer && visualizerType !== "" && visualizerType !== "none"

  onNeedsSpectrumChanged: {
    if (needsSpectrum) {
      SpectrumService.registerComponent("mediapage");
    } else {
      SpectrumService.unregisterComponent("mediapage");
    }
  }

  Component.onCompleted: {
    if (needsSpectrum)
      SpectrumService.registerComponent("mediapage");
  }

  Component.onDestruction: {
    SpectrumService.unregisterComponent("mediapage");
  }

  NScrollView {
    anchors.fill: parent
    verticalPolicy: ScrollBar.AsNeeded
    horizontalPolicy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: parent.width
      spacing: Style.marginM

      // Album Art
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(200 * Style.uiScaleRatio, parent.width * 0.8)

        NImageRounded {
          anchors.fill: parent
          anchors.margins: Style.marginM
          radius: Style.radiusM
          imagePath: MediaService.trackArtUrl
          imageFillMode: Image.PreserveAspectCrop
          fallbackIcon: "disc"
          fallbackIconSize: Style.fontSizeXXXL * 3
          borderWidth: 0
        }
      }

      // Track Info
      NBox {
        Layout.fillWidth: true
        implicitHeight: trackInfoCol.implicitHeight + Style.margin2M

        ColumnLayout {
          id: trackInfoCol
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          NText {
            text: MediaService.trackTitle || "No Media"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          NText {
            text: MediaService.trackArtist || ""
            pointSize: Style.fontSizeM
            color: Color.mOnSurfaceVariant
            Layout.fillWidth: true
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: text !== ""
          }

          NText {
            text: MediaService.trackAlbum || ""
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            Layout.fillWidth: true
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: text !== ""
          }
        }
      }

      // Progress
      NBox {
        Layout.fillWidth: true
        implicitHeight: progressCol.implicitHeight + Style.margin2M
        visible: MediaService.currentPlayer && MediaService.trackLength > 0

        ColumnLayout {
          id: progressCol
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          NSlider {
            Layout.fillWidth: true
            from: 0
            to: 1
            stepSize: 0
            snapAlways: false
            enabled: MediaService.trackLength > 0 && MediaService.canSeek
            heightRatio: 0.4

            property real localSeekRatio: -1
            property real lastSentSeekRatio: -1

            value: !MediaService.isSeeking ? (MediaService.currentPosition / Math.max(MediaService.trackLength, 1)) : (localSeekRatio >= 0 ? localSeekRatio : 0)

            onMoved: {
              localSeekRatio = value;
              seekDebounce.restart();
            }

            onPressedChanged: {
              if (pressed) {
                MediaService.isSeeking = true;
                localSeekRatio = value;
                MediaService.seekByRatio(value);
                lastSentSeekRatio = value;
              } else {
                seekDebounce.stop();
                MediaService.seekByRatio(value);
                MediaService.isSeeking = false;
                localSeekRatio = -1;
                lastSentSeekRatio = -1;
              }
            }

            Timer {
              id: seekDebounce
              interval: 75
              repeat: false
              onTriggered: {
                if (MediaService.isSeeking && parent.localSeekRatio >= 0) {
                  const next = Math.max(0, Math.min(1, parent.localSeekRatio));
                  if (parent.lastSentSeekRatio < 0 || Math.abs(next - parent.lastSentSeekRatio) >= 0.01) {
                    MediaService.seekByRatio(next);
                    parent.lastSentSeekRatio = next;
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 0

            NText {
              text: MediaService.positionString || "0:00"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }

            Item {
              Layout.fillWidth: true
            }

            NText {
              text: MediaService.lengthString || "0:00"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }

      // Playback Controls
      NBox {
        Layout.fillWidth: true
        implicitHeight: controlsRow.implicitHeight + Style.marginM

        RowLayout {
          id: controlsRow
          anchors.centerIn: parent
          spacing: Style.marginXL

          NIconButton {
            icon: "media-prev"
            baseSize: Style.baseWidgetSize * 1.2
            onClicked: MediaService.previous()
          }

          Rectangle {
            implicitWidth: Style.baseWidgetSize * 1.8
            implicitHeight: Style.baseWidgetSize * 1.8
            radius: Style.iRadiusL
            color: Color.mPrimary

            NIcon {
              anchors.centerIn: parent
              icon: MediaService.isPlaying ? "media-pause" : "media-play"
              pointSize: Style.fontSizeXXL
              color: Color.mOnPrimary
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: MediaService.playPause()
            }
          }

          NIconButton {
            icon: "media-next"
            baseSize: Style.baseWidgetSize * 1.2
            onClicked: MediaService.next()
          }
        }
      }
    }
  }
}
