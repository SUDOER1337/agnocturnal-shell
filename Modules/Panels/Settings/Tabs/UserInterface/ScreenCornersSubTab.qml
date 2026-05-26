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
    label: "Show screen corners"
    description: "Display rounded corners on the edge of the screen."
    checked: Settings.data.general.showScreenCorners
    defaultValue: Settings.getDefaultValue("general.showScreenCorners")
    onToggled: checked => Settings.data.general.showScreenCorners = checked
  }

  NToggle {
    label: "Solid black corners"
    description: "Use solid black instead of the bar background color."
    checked: Settings.data.general.forceBlackScreenCorners
    defaultValue: Settings.getDefaultValue("general.forceBlackScreenCorners")
    onToggled: checked => Settings.data.general.forceBlackScreenCorners = checked
  }

  ColumnLayout {
    spacing: Style.marginXXS
    Layout.fillWidth: true

    NValueSlider {
      Layout.fillWidth: true
      label: "Screen corners radius"
      description: "Adjust the rounded corners of the screen."
      from: 0
      to: 2
      stepSize: 0.01
      showReset: true
      value: Settings.data.general.screenRadiusRatio
      defaultValue: Settings.getDefaultValue("general.screenRadiusRatio")
      onMoved: value => Settings.data.general.screenRadiusRatio = value
      text: Math.floor(Settings.data.general.screenRadiusRatio * 100) + "%"
    }
  }
}
