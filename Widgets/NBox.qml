import QtQuick
import qs.Commons

// Rounded group container using the variant surface color.
// To be used in side panels and settings panes to group fields or buttons.
// Opacity is based on panelBackgroundOpacity but clamped to a minimum to avoid full transparency.

Item {
  id: root

  property color color: Color.mSurfaceContainer
  property int containerLevel: -1 // -1=use `color`, 0=Surface, 1=ContainerLow, 2=Container, 3=ContainerHigh
  property bool forceOpaque: false
  property alias radius: bg.radius
  property alias border: bg.border

  readonly property color resolvedColor: {
    if (containerLevel < 0 || containerLevel > 3)
      return root.color;
    switch (containerLevel) {
    case 0:
      return Color.mSurface;
    case 1:
      return Color.mSurfaceContainerLow;
    case 2:
      return Color.mSurfaceContainer;
    case 3:
      return Color.mSurfaceContainerHigh;
    default:
      return root.color;
    }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Style.radiusM
    border.color: Style.boxBorderColor
    border.width: Style.borderS
    color: {
      if (forceOpaque) {
        return root.resolvedColor;
      }

      return Color.smartAlpha(root.resolvedColor);
    }
  }
}
