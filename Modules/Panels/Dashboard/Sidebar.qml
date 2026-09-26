import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // The dashboard deliberately keeps its navigation rail stable. Labels
  // remain available through tooltips without shifting the page layout.
  property bool expanded: false
  property int currentIndex: 0

  signal tabSelected(int index)
  signal openSettingsRequested

  readonly property real sidebarWidth: Math.round(52 * Style.uiScaleRatio)

  implicitWidth: sidebarWidth
  implicitHeight: parent ? parent.height : 0

  NBox {
    anchors.fill: parent
    color: Color.mSurfaceVariant
    radius: Style.radiusL
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginXS

      // Nav items
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.bottomMargin: Style.marginXL

        ListView {
          id: navList
          anchors.fill: parent
          model: [
            {
              icon: "settings-general",
              labelKey: "common.general",
              label: "Quick Settings"
            },
            {
              icon: "device-analytics",
              labelKey: "panels.system.title",
              label: "System"
            },
            {
              icon: "adjustments",
              labelKey: "panels.settings.title",
              label: "Settings"
            },
          ]
          spacing: Style.marginXS
          interactive: contentHeight > height
          currentIndex: root.currentIndex

          Connections {
            target: root
            function onCurrentIndexChanged() {
              navList.currentIndex = root.currentIndex;
            }
          }

          delegate: Rectangle {
            id: delegateItem
            required property int index
            required property string icon
            required property string label
            required property string labelKey

            width: navList.width
            height: Math.round(tabRow.implicitHeight + Style.margin2XS)
            radius: Style.radiusM
            color: {
              if (delegateItem.ListView.isCurrentItem)
                return Color.mPrimary;
              if (hovering)
                return Color.mHover;
              return "transparent";
            }

            property bool hovering: false

            Behavior on color {
              enabled: !Color.isTransitioning
              ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.InOutQuad
              }
            }

            RowLayout {
              id: tabRow
              anchors.fill: parent
              anchors.leftMargin: Style.marginS
              anchors.rightMargin: Style.marginS
              spacing: Style.marginM

              NIcon {
                icon: delegateItem.icon
                color: delegateItem.ListView.isCurrentItem ? Color.mOnPrimary : (delegateItem.hovering ? Color.mOnHover : Color.mOnSurface)
                pointSize: Style.fontSizeXL
                Layout.alignment: Qt.AlignVCenter
              }

              NText {
                text: delegateItem.label
                color: delegateItem.ListView.isCurrentItem ? Color.mOnPrimary : (delegateItem.hovering ? Color.mOnHover : Color.mOnSurface)
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                visible: root.expanded
                opacity: root.expanded ? 1 : 0

                Behavior on opacity {
                  NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.InOutQuad
                  }
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              cursorShape: Qt.PointingHandCursor
              onEntered: {
                delegateItem.hovering = true;
                if (!root.expanded) {
                  TooltipService.show(delegateItem, delegateItem.label);
                }
              }
              onExited: {
                delegateItem.hovering = false;
                if (!root.expanded)
                  TooltipService.hide();
              }
              onCanceled: {
                delegateItem.hovering = false;
                if (!root.expanded)
                  TooltipService.hide();
              }
              onClicked: {
                if (delegateItem.labelKey === "panels.settings.title") {
                  root.currentIndex = 0;
                  root.openSettingsRequested();
                } else {
                  root.currentIndex = delegateItem.index;
                  root.tabSelected(delegateItem.index);
                }
                if (!root.expanded)
                  TooltipService.hide();
              }
            }
          }
        }
      }
    }
  }
}
