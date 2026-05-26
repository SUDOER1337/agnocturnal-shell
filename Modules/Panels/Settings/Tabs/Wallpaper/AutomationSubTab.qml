import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true
  enabled: Settings.data.wallpaper.enabled

  NToggle {
    label: "Scheduled change"
    description: "Automatically change wallpapers at regular intervals."
    checked: Settings.data.wallpaper.automationEnabled
    onToggled: checked => Settings.data.wallpaper.automationEnabled = checked
  }

  ColumnLayout {
    enabled: Settings.data.wallpaper.automationEnabled
    spacing: Style.marginL
    Layout.fillWidth: true

    NComboBox {

      label: "Change mode"
      description: "Choose how wallpapers are selected when changing automatically."
      Layout.fillWidth: true
      model: [
        {
          "key": "random",
          "name": "Random"
        },
        {
          "key": "alphabetical",
          "name": "Alphabetical"
        }
      ]
      currentKey: Settings.data.wallpaper.wallpaperChangeMode || "random"
      onSelected: key => Settings.data.wallpaper.wallpaperChangeMode = key
      defaultValue: Settings.getDefaultValue("wallpaper.wallpaperChangeMode")
    }

    NSpinBox {
      label: "Wallpaper interval"
      description: "How often to change wallpapers automatically."
      Layout.fillWidth: true
      from: 1
      to: 1440
      stepSize: 1
      suffix: "m"
      value: Math.round(Settings.data.wallpaper.randomIntervalSec / 60)
      defaultValue: Settings.getDefaultValue("wallpaper.randomIntervalSec") !== undefined ? Math.round(Settings.getDefaultValue("wallpaper.randomIntervalSec") / 60) : undefined
      onValueChanged: {
        let newSec = value * 60;
        if (newSec !== Settings.data.wallpaper.randomIntervalSec) {
          Settings.data.wallpaper.randomIntervalSec = newSec;
          WallpaperService.restartRandomWallpaperTimer();
        }
      }
    }
  }
}
