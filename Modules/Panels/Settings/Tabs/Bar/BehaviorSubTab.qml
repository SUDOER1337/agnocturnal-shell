import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property string effectiveWheelAction: Settings.data.bar.mouseWheelAction || "none"
  readonly property string effectiveMiddleClickAction: Settings.data.bar.middleClickAction || "none"
  readonly property string effectiveRightClickAction: Settings.data.bar.rightClickAction || "controlCenter"

  NComboBox {
    Layout.fillWidth: true
    label: "Bar mouse wheel action"
    description: "Choose what the mouse wheel does on empty areas of the bar."
    model: {
      var items = [
            {
              "key": "none",
              "name": "None"
            },
            {
              "key": "volume",
              "name": "Volume"
            },
            {
              "key": "workspace",
              "name": "Workspace"
            }
          ];
      if (CompositorService.isNiri) {
        items.push({
                     "key": "content",
                     "name": "Content"
                   });
      }
      return items;
    }
    currentKey: root.effectiveWheelAction
    defaultValue: Settings.getDefaultValue("bar.mouseWheelAction")
    onSelected: key => Settings.data.bar.mouseWheelAction = key
  }

  NToggle {
    Layout.fillWidth: true
    label: "Reverse scrolling"
    description: "Reverse the interpreted scroll direction"
    checked: Settings.data.bar.reverseScroll
    defaultValue: Settings.getDefaultValue("bar.reverseScroll")
    onToggled: checked => Settings.data.bar.reverseScroll = checked
    visible: Settings.data.bar.mouseWheelAction !== "none"
  }

  NToggle {
    Layout.fillWidth: true
    label: "Wrap around"
    description: "When enabled, scrolling continues from the last item to the first."
    checked: Settings.data.bar.mouseWheelWrap
    defaultValue: Settings.getDefaultValue("bar.mouseWheelWrap")
    onToggled: checked => Settings.data.bar.mouseWheelWrap = checked
    visible: Settings.data.bar.mouseWheelAction === "workspace"
  }

  NComboBox {
    Layout.fillWidth: true
    label: "Bar middle click action"
    description: "Choose what middle click does on empty areas of the bar."
    model: [
      {
        "key": "none",
        "name": "None"
      },
      {
        "key": "controlCenter",
        "name": "Control center"
      },
      {
        "key": "settings",
        "name": "Settings"
      },
      {
        "key": "launcherPanel",
        "name": "Open launcher"
      },
      {
        "key": "command",
        "name": "Run custom command"
      }
    ]
    currentKey: root.effectiveMiddleClickAction
    defaultValue: Settings.getDefaultValue("bar.middleClickAction")
    onSelected: key => Settings.data.bar.middleClickAction = key
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Middle click command"
    description: "Command to execute on middle click."
    placeholderText: "niri msg action toggle-overview"
    text: Settings.data.bar.middleClickCommand
    fontFamily: Settings.data.ui.fontFixed
    onTextChanged: Settings.data.bar.middleClickCommand = text
    visible: Settings.data.bar.middleClickAction === "command"
  }

  NToggle {
    Layout.fillWidth: true
    label: "Middle click follow mouse"
    description: "Open the selected middle-click panel at the cursor position."
    checked: Settings.data.bar.middleClickFollowMouse
    defaultValue: Settings.getDefaultValue("bar.middleClickFollowMouse")
    onToggled: checked => Settings.data.bar.middleClickFollowMouse = checked
    visible: Settings.data.bar.middleClickAction !== "none" && Settings.data.bar.middleClickAction !== "command" && !(Settings.data.bar.middleClickAction === "settings" && Settings.data.ui.settingsPanelMode === "window")
  }

  NComboBox {
    Layout.fillWidth: true
    label: "Bar right click action"
    description: "Choose what right click does on empty areas of the bar."
    model: [
      {
        "key": "none",
        "name": "None"
      },
      {
        "key": "controlCenter",
        "name": "Control center"
      },
      {
        "key": "settings",
        "name": "Settings"
      },
      {
        "key": "launcherPanel",
        "name": "Open launcher"
      },
      {
        "key": "command",
        "name": "Run custom command"
      }
    ]
    currentKey: root.effectiveRightClickAction
    defaultValue: Settings.getDefaultValue("bar.rightClickAction")
    onSelected: key => Settings.data.bar.rightClickAction = key
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Right click command"
    description: "Command to execute on right click."
    placeholderText: "notify-send \"Right click\""
    text: Settings.data.bar.rightClickCommand
    fontFamily: Settings.data.ui.fontFixed
    onTextChanged: Settings.data.bar.rightClickCommand = text
    visible: Settings.data.bar.rightClickAction === "command"
  }

  NToggle {
    Layout.fillWidth: true
    label: "Right click follow mouse"
    description: "Open the selected right-click panel at the cursor position."
    checked: Settings.data.bar.rightClickFollowMouse
    defaultValue: Settings.getDefaultValue("bar.rightClickFollowMouse")
    onToggled: checked => Settings.data.bar.rightClickFollowMouse = checked
    visible: Settings.data.bar.rightClickAction !== "none" && Settings.data.bar.rightClickAction !== "command" && !(Settings.data.bar.rightClickAction === "settings" && Settings.data.ui.settingsPanelMode === "window")
  }
}
