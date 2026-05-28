// File: Widgets/NSaturationSlider.qml
// Saturation control slider for a single color slot.
// Shows slot name, real-time color swatch, slider, percentage, and reset button.

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  property string slotName: ""
  property real saturationValue: 1.0
  property real defaultSaturation: 1.0
  property color slotColor: Color.mPrimary

  spacing: Style.marginM
  Layout.fillWidth: true

  signal saturationChanged(real value)

  readonly property bool isChanged: Math.abs(saturationValue - defaultSaturation) > 0.01

  // Slot label
  NText {
    text: root.slotName
    pointSize: Style.fontSizeM
    color: Color.mOnSurface
    Layout.preferredWidth: 80 * Style.uiScaleRatio
    Layout.alignment: Qt.AlignVCenter
    elide: Text.ElideRight
    maximumLineCount: 1
  }

  // Color swatch: preview of the saturation-adjusted color
  Rectangle {
    id: swatch
    width: 20 * Style.uiScaleRatio
    height: 20 * Style.uiScaleRatio
    radius: Style.radiusS
    color: root.slotColor
    border.width: Style.borderS
    border.color: Color.mOutline
    Layout.alignment: Qt.AlignVCenter
  }

  // Slider
  NSlider {
    id: slider
    Layout.fillWidth: true
    from: 0.0
    to: 1.5
    value: root.saturationValue
    stepSize: 0.01
    fillColor: Color.mPrimary

    onMoved: {
      root.saturationChanged(value);
    }
  }

  // Percentage label
  NText {
    text: Math.round(slider.value * 100) + "%"
    pointSize: Style.fontSizeS
    family: Settings.data.ui.fontFixed
    color: Color.mOnSurfaceVariant
    Layout.preferredWidth: 40 * Style.uiScaleRatio
    horizontalAlignment: Text.AlignRight
    Layout.alignment: Qt.AlignVCenter
  }

  // Reset button
  NIconButton {
    icon: "restore"
    baseSize: Style.baseWidgetSize * 0.7
    tooltipText: "Reset"
    enabled: root.isChanged
    opacity: enabled ? 1.0 : 0.4
    onClicked: root.saturationChanged(root.defaultSaturation)
    Layout.alignment: Qt.AlignVCenter
  }
}
