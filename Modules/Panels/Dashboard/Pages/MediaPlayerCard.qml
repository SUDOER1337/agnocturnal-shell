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

// ============================================================
// MediaPlayerCard - Full-featured media player embedded as a card.
// Preserves the standalone MediaPlayerPanel look (album art, visualizer,
// scrollable metadata, seek slider, prev/play/next, player selector) while
// rendering as a fixed top card inside the combined Dashboard.
//
// The card uses a portrait layout: album art on top, then metadata, seek bar
// and transport controls stacked in a centered column. All other visual
// settings (visualizer type, scrolling mode, album art toggle, album art
// size) come from the MediaMini bar widget's settings.
// ============================================================
NBox {
  id: root

  // === Bar/widget settings (same source as the standalone player) ===
  property ShellScreen screen

  property var mediaMiniSettings: {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    return widget ? widget.widgetSettings : null;
  }

  function refreshMediaMiniSettings() {
    const widget = BarService.lookupWidget("MediaMini", screen?.name);
    root.mediaMiniSettings = widget ? widget.widgetSettings : null;
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      root.refreshMediaMiniSettings();
    }
  }

  Connections {
    target: Settings
    function onSettingsSaved() {
      root.refreshMediaMiniSettings();
    }
  }

  readonly property string visualizerType: (mediaMiniSettings && mediaMiniSettings.visualizerType !== undefined) ? mediaMiniSettings.visualizerType : "linear"
  readonly property bool showArtistFirst: !!(mediaMiniSettings && mediaMiniSettings.showArtistFirst !== undefined ? mediaMiniSettings.showArtistFirst : true)
  readonly property bool showAlbumArt: !!(mediaMiniSettings && mediaMiniSettings.panelShowAlbumArt !== undefined ? mediaMiniSettings.panelShowAlbumArt : true)
  readonly property bool showVisualizer: !!(mediaMiniSettings && mediaMiniSettings.showVisualizer !== undefined ? mediaMiniSettings.showVisualizer : true)
  readonly property string panelVisualizerPlacement: (mediaMiniSettings && mediaMiniSettings.panelVisualizerPlacement !== undefined) ? mediaMiniSettings.panelVisualizerPlacement : "art"
  readonly property int panelAlbumArtSize: (mediaMiniSettings && mediaMiniSettings.panelAlbumArtSize !== undefined) ? mediaMiniSettings.panelAlbumArtSize : 180
  readonly property string scrollingMode: (mediaMiniSettings && mediaMiniSettings.scrollingMode !== undefined) ? mediaMiniSettings.scrollingMode : "hover"

  // Embedded card: narrow full-height column, content column centered and
  // width-capped. The header pill and the album art are both capped to stay
  // inside this width, so a long MPRIS identity or an oversized art setting
  // cannot push the column wider than intended.
  readonly property real cardContentWidth: Math.round(216 * Style.uiScaleRatio)
  readonly property real maxArtSize: 200
  readonly property real contentImplicitWidth: Math.max(headerRow.implicitWidth, root.cardContentWidth) + Style.margin2S

  readonly property bool isPanelOpen: {
    const p = PanelService.getPanel("dashboardPanel", root.screen);
    return p ? p.isPanelOpen : false;
  }

  readonly property bool needsSpectrum: root.isPanelOpen && root.showVisualizer && root.visualizerType !== "" && root.visualizerType !== "none"

  onNeedsSpectrumChanged: {
    if (root.needsSpectrum) {
      SpectrumService.registerComponent("ccv5-mediacard");
    } else {
      SpectrumService.unregisterComponent("ccv5-mediacard");
    }
  }

  Component.onCompleted: {
    if (root.needsSpectrum) {
      SpectrumService.registerComponent("ccv5-mediacard");
    }
  }

  Component.onDestruction: {
    SpectrumService.unregisterComponent("ccv5-mediacard");
  }

  implicitHeight: mainLayout.implicitHeight + Style.margin2S
  implicitWidth: contentImplicitWidth

  Item {
    anchors.fill: parent
    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskThresholdMin: 0.95
      maskSpreadAtMin: 0.15
      maskSource: ShaderEffectSource {
        sourceItem: Rectangle {
          width: root.width
          height: root.height
          radius: root.radius
          color: "white"
        }
      }
    }

    Image {
      id: blurredCover
      readonly property int dim: Math.round(256 * Style.uiScaleRatio)
      anchors.fill: parent
      visible: source.toString() !== ""
      source: MediaService.trackArtUrl
      sourceSize: Qt.size(dim, dim)
      fillMode: Image.PreserveAspectCrop
      layer.enabled: true
      layer.smooth: true
      layer.effect: MultiEffect {
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 60
        blur: 1
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Color.mSurface
      opacity: 0.65
      radius: root.radius
    }

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      radius: root.radius
      border.color: root.border.color
      border.width: root.border.width
    }
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: Style.marginS
    spacing: Style.marginS

    // === Header: title + player selector ===
    RowLayout {
      id: headerRow
      Layout.fillWidth: true
      spacing: Style.marginM

      NIcon {
        icon: "music"
        pointSize: Style.fontSizeL
        color: Color.mPrimary
      }
      Rectangle {
        radius: Style.iRadiusS
        color: playerSelectorMouse.containsMouse ? Color.mPrimary : "transparent"
        implicitWidth: playerRow.implicitWidth + Style.marginM
        implicitHeight: Style.baseWidgetSize * 0.8
        visible: MediaService.getAvailablePlayers().length > 1

        RowLayout {
          id: playerRow
          anchors.centerIn: parent
          spacing: Style.marginXS

          NText {
            text: MediaService.currentPlayer ? MediaService.currentPlayer.identity : "Select Player"
            pointSize: Style.fontSizeXS
            color: playerSelectorMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurfaceVariant
            // Capped so a long player identity cannot widen the card column;
            // NText already elides right and never wraps.
            Layout.preferredWidth: Math.round(96 * Style.uiScaleRatio)
            Layout.maximumWidth: Math.round(96 * Style.uiScaleRatio)
          }
          NIcon {
            icon: "chevron-down"
            pointSize: Style.fontSizeXS
            color: playerSelectorMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurfaceVariant
          }
        }

        MouseArea {
          id: playerSelectorMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: playerContextMenu.open()
        }

        Popup {
          id: playerContextMenu
          x: 0
          y: parent.height
          width: 160
          padding: Style.marginS

          background: Rectangle {
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS
            radius: Style.iRadiusM
          }

          contentItem: ColumnLayout {
            spacing: 0
            Repeater {
              model: MediaService.getAvailablePlayers()
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: "transparent"

                Rectangle {
                  anchors.fill: parent
                  color: itemMouse.containsMouse ? Color.mPrimary : "transparent"
                  radius: Style.iRadiusS
                }

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.marginS
                  spacing: Style.marginS

                  NIcon {
                    visible: MediaService.currentPlayer && MediaService.currentPlayer.identity === modelData.identity
                    icon: "check"
                    color: itemMouse.containsMouse ? Color.mOnPrimary : Color.mPrimary
                    pointSize: Style.fontSizeS
                  }

                  NText {
                    text: modelData.identity
                    pointSize: Style.fontSizeS
                    color: itemMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurface
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: itemMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    MediaService.currentPlayer = modelData;
                    playerContextMenu.close();
                  }
                }
              }
            }
          }
        }
      }
    }

    // === Player body: album art + controls ===
    Item {
      id: mediaBody
      Layout.fillWidth: true
      Layout.preferredHeight: mediaStack.implicitHeight + Style.margin2M

      // Visualizer background for content area
      Loader {
        anchors.fill: parent
        z: 0
        active: !!(root.needsSpectrum && root.panelVisualizerPlacement !== "none" && (!root.showAlbumArt || root.panelVisualizerPlacement !== "art"))
        sourceComponent: visualizerSource
      }

      ColumnLayout {
        id: mediaStack
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, root.cardContentWidth)
        spacing: Style.marginM

        // Album art
        Item {
          id: albumArtItem
          readonly property real compactArtSize: Math.round(Math.min(root.panelAlbumArtSize, root.maxArtSize) * Style.uiScaleRatio)

          Layout.preferredWidth: compactArtSize
          Layout.preferredHeight: compactArtSize
          Layout.minimumWidth: compactArtSize
          Layout.maximumWidth: compactArtSize
          Layout.minimumHeight: compactArtSize
          Layout.maximumHeight: compactArtSize
          Layout.alignment: Qt.AlignHCenter
          visible: root.showAlbumArt

          NImageRounded {
            anchors.fill: parent
            radius: Style.radiusM
            imagePath: MediaService.trackArtUrl
            imageFillMode: Image.PreserveAspectCrop
            fallbackIcon: "disc"
            fallbackIconSize: Style.fontSizeXXXL * 3
            borderWidth: 0
          }

          Loader {
            anchors.fill: parent
            anchors.margins: Style.marginS
            z: 2
            active: !!(root.needsSpectrum && root.showAlbumArt && root.panelVisualizerPlacement === "art")
            sourceComponent: visualizerSource
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          NScrollText {
            Layout.fillWidth: true
            maxWidth: parent.width
            text: {
              if (root.showArtistFirst) {
                return MediaService.trackArtist || (MediaService.trackAlbum || "Unknown Artist");
              } else {
                return MediaService.trackTitle || "No Media";
              }
            }

            scrollMode: {
              if (root.scrollingMode === "always")
                return NScrollText.ScrollMode.Always;
              if (root.scrollingMode === "hover")
                return NScrollText.ScrollMode.Hover;
              return NScrollText.ScrollMode.Never;
            }
            fadeExtent: 0.01
            fadeCornerRadius: Style.radiusM

            delegate: NText {
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              horizontalAlignment: Text.AlignLeft
              elide: Text.ElideNone
              wrapMode: Text.NoWrap
            }
          }

          NScrollText {
            Layout.fillWidth: true
            maxWidth: parent.width
            text: {
              if (root.showArtistFirst) {
                return MediaService.trackTitle || "No Media";
              } else {
                return MediaService.trackArtist || (MediaService.trackAlbum || "Unknown Artist");
              }
            }

            scrollMode: {
              if (root.scrollingMode === "always")
                return NScrollText.ScrollMode.Always;
              if (root.scrollingMode === "hover")
                return NScrollText.ScrollMode.Hover;
              return NScrollText.ScrollMode.Never;
            }
            fadeExtent: 0.01
            fadeCornerRadius: Style.radiusM

            delegate: NText {
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
              horizontalAlignment: Text.AlignLeft
              elide: Text.ElideNone
              wrapMode: Text.NoWrap
            }
          }
        }

        Item {
          id: progressWrapper
          visible: (MediaService.currentPlayer && MediaService.trackLength > 0)
          Layout.fillWidth: true
          Layout.preferredHeight: progressColumn.implicitHeight

          property real localSeekRatio: -1
          property real lastSentSeekRatio: -1
          property real seekEpsilon: 0.01
          property real progressRatio: {
            if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
              return 0;
            const r = MediaService.currentPosition / MediaService.trackLength;
            if (isNaN(r) || !isFinite(r))
              return 0;
            return Math.max(0, Math.min(1, r));
          }

          Timer {
            id: seekDebounce
            interval: 75
            repeat: false
            onTriggered: {
              if (MediaService.isSeeking && progressWrapper.localSeekRatio >= 0) {
                const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio));
                if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                  MediaService.seekByRatio(next);
                  progressWrapper.lastSentSeekRatio = next;
                }
              }
            }
          }

          ColumnLayout {
            id: progressColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 2

            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize * 0.4

              NSlider {
                id: progressSlider
                anchors.fill: parent
                from: 0
                to: 1
                stepSize: 0
                snapAlways: false
                enabled: MediaService.trackLength > 0 && MediaService.canSeek
                heightRatio: 0.4

                value: (!MediaService.isSeeking) ? progressWrapper.progressRatio : (progressWrapper.localSeekRatio >= 0 ? progressWrapper.localSeekRatio : 0)

                onMoved: {
                  progressWrapper.localSeekRatio = value;
                  seekDebounce.restart();
                }
                onPressedChanged: {
                  if (pressed) {
                    MediaService.isSeeking = true;
                    progressWrapper.localSeekRatio = value;
                    MediaService.seekByRatio(value);
                    progressWrapper.lastSentSeekRatio = value;
                  } else {
                    seekDebounce.stop();
                    MediaService.seekByRatio(value);
                    MediaService.isSeeking = false;
                    progressWrapper.localSeekRatio = -1;
                    progressWrapper.lastSentSeekRatio = -1;
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
                visible: progressWrapper.visible
              }

              Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
              }

              NText {
                text: MediaService.lengthString || "0:00"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignRight
                visible: progressWrapper.visible
              }
            }
          }
        }

        RowLayout {
          spacing: Style.marginL
          Layout.alignment: Qt.AlignHCenter

          NIconButton {
            icon: "media-prev"
            baseSize: Style.baseWidgetSize * 0.9
            onClicked: MediaService.previous()
          }

          Rectangle {
            implicitWidth: Style.baseWidgetSize * 1.3
            implicitHeight: Style.baseWidgetSize * 1.3
            radius: Style.iRadiusM
            color: Color.mPrimary

            NIcon {
              anchors.centerIn: parent
              icon: MediaService.isPlaying ? "media-pause" : "media-play"
              pointSize: Style.fontSizeL
              color: Color.mOnPrimary
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: MediaService.playPause()
            }
          }

          NIconButton {
            icon: "media-next"
            baseSize: Style.baseWidgetSize * 0.9
            onClicked: MediaService.next()
          }
        }
      }
    }
  }

  // Visualizer Components
  readonly property Component visualizerSource: {
    switch (root.visualizerType) {
    case "linear":
      return linearComponent;
    case "mirrored":
      return mirroredComponent;
    case "wave":
      return waveComponent;
    default:
      return null;
    }
  }

  Component {
    id: linearComponent
    NLinearSpectrum {
      anchors.fill: parent
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.4
      barPosition: Settings.getBarPositionForScreen(root.screen?.name)
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  Component {
    id: mirroredComponent
    NMirroredSpectrum {
      anchors.fill: parent
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.9
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  Component {
    id: waveComponent
    NWaveSpectrum {
      anchors.fill: parent
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.4
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }
}
