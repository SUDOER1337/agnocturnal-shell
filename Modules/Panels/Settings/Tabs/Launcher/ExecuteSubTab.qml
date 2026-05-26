import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NTextInput {
    label: "Terminal command"
    description: "Command to launch a terminal. E.g. 'kitty -e' or 'gnome-terminal --'."
    Layout.fillWidth: true
    text: Settings.data.appLauncher.terminalCommand
    onTextChanged: Settings.data.appLauncher.terminalCommand = text
  }

  NToggle {
    label: "Enable custom launch prefix"
    description: "Use a custom prefix for launching applications instead of the default method."
    checked: Settings.data.appLauncher.customLaunchPrefixEnabled
    onToggled: checked => Settings.data.appLauncher.customLaunchPrefixEnabled = checked
    defaultValue: Settings.getDefaultValue("appLauncher.customLaunchPrefixEnabled")
  }

  NTextInput {
    label: "Custom launch prefix"
    description: "Prefix commands with a custom launcher (e.g. 'runapp' for systemd integration)."
    Layout.fillWidth: true
    text: Settings.data.appLauncher.customLaunchPrefix
    enabled: Settings.data.appLauncher.customLaunchPrefixEnabled
    visible: Settings.data.appLauncher.customLaunchPrefixEnabled
    onTextChanged: Settings.data.appLauncher.customLaunchPrefix = text
  }

  NTextInput {
    label: "Annotation tool"
    description: "Command to run when clicking the annotate button in clipboard history. The image will be piped to this command."
    Layout.fillWidth: true
    text: Settings.data.appLauncher.screenshotAnnotationTool
    placeholderText: "e.g. 'gradia', 'satty -f -'"
    onTextChanged: Settings.data.appLauncher.screenshotAnnotationTool = text
  }
}
