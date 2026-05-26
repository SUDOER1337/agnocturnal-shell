import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NComboBox {
    label: "Visualization type"
    description: "Choose a visualization type for media playback."
    model: [
      {
        "key": "none",
        "name": "None"
      },
      {
        "key": "linear",
        "name": "Linear"
      },
      {
        "key": "mirrored",
        "name": "Mirrored"
      },
      {
        "key": "wave",
        "name": "Wave"
      }
    ]
    currentKey: Settings.data.audio.visualizerType
    defaultValue: Settings.getDefaultValue("audio.visualizerType")
    onSelected: key => Settings.data.audio.visualizerType = key
  }

  NToggle {
    label: "Mirror spectrum"
    description: "Mirror the spectrum so low frequencies are in the center. When off, low frequencies are on the left and high on the right."
    checked: Settings.data.audio.spectrumMirrored
    defaultValue: Settings.getDefaultValue("audio.spectrumMirrored")
    onToggled: Settings.data.audio.spectrumMirrored = checked
  }

  NComboBox {
    label: "Frame rate"
    description: "Higher rates are smoother but use more resources."
    model: [
      {
        "key": "30",
        "name": "{fps} FPS"
      },
      {
        "key": "60",
        "name": "{fps} FPS"
      },
      {
        "key": "100",
        "name": "{fps} FPS"
      },
      {
        "key": "120",
        "name": "{fps} FPS"
      },
      {
        "key": "144",
        "name": "{fps} FPS"
      },
      {
        "key": "165",
        "name": "{fps} FPS"
      },
      {
        "key": "240",
        "name": "{fps} FPS"
      }
    ]
    currentKey: Settings.data.audio.spectrumFrameRate
    defaultValue: Settings.getDefaultValue("audio.spectrumFrameRate")
    onSelected: key => Settings.data.audio.spectrumFrameRate = key
  }
}
