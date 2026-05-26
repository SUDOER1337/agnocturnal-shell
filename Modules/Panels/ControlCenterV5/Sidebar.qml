import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property bool expanded: true
  property int currentIndex: 0
  property bool searching: false
  property string searchText: ""

  signal tabSelected(int index)

  readonly property real sidebarWidth: expanded ? Math.round(200 * Style.uiScaleRatio) : Math.round(52 * Style.uiScaleRatio)

  onExpandedChanged: {
    if (!expanded) {
      searchText = "";
      searching = false;
      searchInput.text = "";
    }
  }

  implicitWidth: sidebarWidth
  implicitHeight: parent ? parent.height : 0

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.InOutQuad
    }
  }

  NBox {
    anchors.fill: parent
    color: Color.mSurfaceVariant
    radius: Style.radiusL
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginXS

      // Toggle button
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(toggleRow.implicitHeight + Style.margin2S)

        Rectangle {
          id: toggleBtn
          width: Math.round(toggleRow.implicitWidth + Style.margin2S)
          height: parent.height
          anchors.left: parent.left
          radius: Style.radiusS
          color: toggleMouse.containsMouse ? Color.mHover : "transparent"

          RowLayout {
            id: toggleRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Style.marginS
            spacing: 0

            NIcon {
              icon: root.expanded ? "layout-sidebar-right-expand" : "layout-sidebar-left-expand"
              color: toggleMouse.containsMouse ? Color.mOnHover : Color.mOnSurface
              pointSize: Style.fontSizeXL
            }
          }

          MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.expanded = !root.expanded;
              TooltipService.hide();
            }
            onEntered: {
              TooltipService.show(toggleBtn, root.expanded ? "Collapse sidebar" : "Expand sidebar");
            }
            onExited: TooltipService.hide()
          }
        }
      }

      // Search input (visible when expanded)
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: searchInput.implicitHeight
        visible: root.expanded
        opacity: root.expanded ? 1 : 0
        color: "transparent"

        Behavior on opacity {
          NumberAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad }
        }

        NTextInput {
          id: searchInput
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          placeholderText: "Search"
          inputIconName: "search"
          onTextChanged: {
            root.searchText = text;
            root.searching = text.trim() !== "";
          }
        }
      }

      // Search button for collapsed sidebar
      Rectangle {
        id: searchCollapsedBtn
        visible: !root.expanded
        width: Math.round(searchCollapsedRow.implicitWidth + Style.margin2S)
        height: parent.height > 0 ? Math.round(searchCollapsedRow.implicitHeight + Style.margin2S) : 0
        anchors.left: parent.left
        radius: Style.radiusS
        color: searchCollapsedMouse.containsMouse ? Color.mHover : "transparent"

        RowLayout {
          id: searchCollapsedRow
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS
          spacing: 0

          NIcon {
            icon: "search"
            color: searchCollapsedMouse.containsMouse ? Color.mOnHover : Color.mOnSurface
            pointSize: Style.fontSizeXL
          }
        }

        MouseArea {
          id: searchCollapsedMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.expanded = true;
            Qt.callLater(() => searchInput.inputItem?.forceActiveFocus());
          }
          onEntered: TooltipService.show(searchCollapsedBtn, "Search")
          onExited: TooltipService.hide()
        }
      }

      // Nav items
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.bottomMargin: Style.marginXL

        ListView {
          id: navList
          anchors.fill: parent
          model: [
            { icon: "settings-general", labelKey: "common.general", label: "Quick Settings" },
            { icon: "music", labelKey: "panels.media.title", label: "Media" },
            { icon: "device-analytics", labelKey: "panels.system.title", label: "System" },
            { icon: "adjustments", labelKey: "panels.settings.title", label: "Settings" },
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
              ColorAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad }
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
                  NumberAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad }
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
                if (!root.expanded) TooltipService.hide();
              }
              onCanceled: {
                delegateItem.hovering = false;
                if (!root.expanded) TooltipService.hide();
              }
              onClicked: {
                root.currentIndex = delegateItem.index;
                root.tabSelected(delegateItem.index);
                if (!root.expanded) TooltipService.hide();
              }
            }
          }
        }
      }
    }
  }
}
