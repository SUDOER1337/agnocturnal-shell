import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  width: parent.width

  // Enable/Disable Toggle
  NToggle {
    label: "Enable hooks"
    description: "Enable or disable all hook commands."
    checked: Settings.data.hooks.enabled
    onToggled: checked => Settings.data.hooks.enabled = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Info section
  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NLabel {
      label: "Available parameters"
      description: "• Wallpaper hook: $1 = wallpaper path, $2 = screen name, $3 = theme (dark/light)<br>• Color generation hook: $1 = theme (dark/light)<br>• Theme toggle hook: $1 = true/false (Dark Mode state)<br>• Screen lock/unlock hooks: $1 = lock/unlock (screen lock state)<br>• Performance mode hooks: No parameters<br>• Session hook: $1 = action (shutdown/reboot)"
    }
  }
}
