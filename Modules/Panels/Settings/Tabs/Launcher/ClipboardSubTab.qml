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

  NToggle {
    label: "Enable clipboard history"
    description: "Access previously copied items from the launcher."
    checked: Settings.data.appLauncher.enableClipboardHistory
    onToggled: checked => Settings.data.appLauncher.enableClipboardHistory = checked
    defaultValue: Settings.getDefaultValue("appLauncher.enableClipboardHistory")
  }

  NToggle {
    label: "Enable clip preview"
    description: "Show a preview of the clipboard content when using the >clip command."
    checked: Settings.data.appLauncher.enableClipPreview
    onToggled: checked => Settings.data.appLauncher.enableClipPreview = checked
    defaultValue: Settings.getDefaultValue("appLauncher.enableClipPreview")
    enabled: Settings.data.appLauncher.enableClipboardHistory
  }

  NToggle {
    label: "Wrap clipboard text"
    description: "Wrap text in the clipboard list instead of truncating it."
    checked: Settings.data.appLauncher.clipboardWrapText
    onToggled: checked => Settings.data.appLauncher.clipboardWrapText = checked
    defaultValue: Settings.getDefaultValue("appLauncher.clipboardWrapText")
    enabled: Settings.data.appLauncher.enableClipboardHistory
  }

  NToggle {
    label: "Auto paste"
    description: "Automatically paste the selected clipboard item. Requires wtype."
    checked: Settings.data.appLauncher.autoPasteClipboard
    onToggled: checked => Settings.data.appLauncher.autoPasteClipboard = checked
    defaultValue: Settings.getDefaultValue("appLauncher.autoPasteClipboard")
    enabled: Settings.data.appLauncher.enableClipboardHistory && ProgramCheckerService.wtypeAvailable
  }

  NToggle {
    label: "Enable Smart Icons"
    description: "Show specific icons for links, files, colors, and code instead of a generic clipboard icon."
    checked: Settings.data.appLauncher.enableClipboardSmartIcons
    onToggled: checked => Settings.data.appLauncher.enableClipboardSmartIcons = checked
    defaultValue: Settings.getDefaultValue("appLauncher.enableClipboardSmartIcons")
    enabled: Settings.data.appLauncher.enableClipboardHistory
  }

  NToggle {
    label: "Enable Category Chips"
    description: "Show a tab bar to filter clipboard history by type (Images, Links, Files, Code, etc)."
    checked: Settings.data.appLauncher.enableClipboardChips
    onToggled: checked => Settings.data.appLauncher.enableClipboardChips = checked
    defaultValue: Settings.getDefaultValue("appLauncher.enableClipboardChips")
    enabled: Settings.data.appLauncher.enableClipboardHistory
  }

  NDivider {
    Layout.fillWidth: true
    visible: Settings.data.appLauncher.enableClipboardHistory
  }

  NTextInput {
    label: "Text watch command"
    description: "Full command string passed to wl-paste for text changes. (requires restart)"
    Layout.fillWidth: true
    text: Settings.data.appLauncher.clipboardWatchTextCommand
    onTextChanged: Settings.data.appLauncher.clipboardWatchTextCommand = text
    enabled: Settings.data.appLauncher.enableClipboardHistory
    visible: Settings.data.appLauncher.enableClipboardHistory
  }

  NTextInput {
    label: "Image watch command"
    description: "Full command string passed to wl-paste for image changes. (requires restart)"
    Layout.fillWidth: true
    text: Settings.data.appLauncher.clipboardWatchImageCommand
    onTextChanged: Settings.data.appLauncher.clipboardWatchImageCommand = text
    enabled: Settings.data.appLauncher.enableClipboardHistory
    visible: Settings.data.appLauncher.enableClipboardHistory
  }
}
