import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NToggle {
    Layout.fillWidth: true
    label: "Enable wallpaper rendering in performance mode"
    description: "Keep desktop, overview, and lock screen wallpapers visible while Noctalia performance mode is enabled."
    checked: !Settings.data.noctaliaPerformance.disableWallpaper
    defaultValue: !Settings.getDefaultValue("noctaliaPerformance.disableWallpaper")
    onToggled: checked => Settings.data.noctaliaPerformance.disableWallpaper = !checked
  }

  NToggle {
    Layout.fillWidth: true
    label: "Enable desktop widgets in performance mode"
    description: "Keep desktop widgets visible while Noctalia performance mode is enabled."
    checked: !Settings.data.noctaliaPerformance.disableDesktopWidgets
    defaultValue: !Settings.getDefaultValue("noctaliaPerformance.disableDesktopWidgets")
    onToggled: checked => Settings.data.noctaliaPerformance.disableDesktopWidgets = !checked
  }
}
