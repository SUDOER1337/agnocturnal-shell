import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../../../Helpers/QtObj2JS.js" as QtObj2JS
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // Fonts
  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    // Font configuration section
    ColumnLayout {
      spacing: Style.marginL
      Layout.fillWidth: true

      NSearchableComboBox {
        label: "Default font"
        description: "Main font used throughout the interface."
        model: FontService.availableFonts
        currentKey: Settings.data.ui.fontDefault
        placeholder: "Select default font..."
        searchPlaceholder: "Search font..."
        popupHeight: 420
        defaultValue: Settings.getDefaultValue("ui.fontDefault")
        settingsPath: "ui.fontDefault"
        onSelected: key => Settings.data.ui.fontDefault = key
      }

      NSearchableComboBox {
        label: "Monospaced font"
        description: "Monospaced font used for numbers and stats display."
        model: FontService.monospaceFonts
        currentKey: Settings.data.ui.fontFixed
        placeholder: "Select monospace font..."
        searchPlaceholder: "Search monospace font..."
        popupHeight: 320
        defaultValue: Settings.getDefaultValue("ui.fontFixed")
        settingsPath: "ui.fontFixed"
        onSelected: key => Settings.data.ui.fontFixed = key
      }

      NValueSlider {
        Layout.fillWidth: true
        label: "Default font size"
        description: "Increase or decrease the size of the standard text."
        from: 0.75
        to: 1.25
        stepSize: 0.01
        showReset: true
        value: Settings.data.ui.fontDefaultScale
        defaultValue: Settings.getDefaultValue("ui.fontDefaultScale")
        onMoved: value => Settings.data.ui.fontDefaultScale = value
        text: Math.floor(Settings.data.ui.fontDefaultScale * 100) + "%"
      }

      NValueSlider {
        Layout.fillWidth: true
        label: "Monospaced font size"
        description: "Increase or decrease the size of the monospaced text."
        from: 0.75
        to: 1.25
        stepSize: 0.01
        showReset: true
        value: Settings.data.ui.fontFixedScale
        defaultValue: Settings.getDefaultValue("ui.fontFixedScale")
        onMoved: value => Settings.data.ui.fontFixedScale = value
        text: Math.floor(Settings.data.ui.fontFixedScale * 100) + "%"
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NToggle {
    Layout.fillWidth: true
    label: "Reverse scrolling"
    description: "Reverse the interpreted scroll direction"
    checked: Settings.data.general.reverseScroll
    defaultValue: Settings.getDefaultValue("general.reverseScroll")
    onToggled: checked => Settings.data.general.reverseScroll = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: "Smooth scrolling"
    description: "Animate list scrolling for a smoother wheel experience."
    checked: Settings.data.general.smoothScrollEnabled
    defaultValue: Settings.getDefaultValue("general.smoothScrollEnabled")
    onToggled: checked => Settings.data.general.smoothScrollEnabled = checked
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  RowLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    NButton {
      icon: "external-link"
      text: "Documentation"
      outlined: true
      Layout.fillWidth: true
      onClicked: {
        Qt.openUrlExternally("https://docs.noctalia.dev");
      }
    }

    NButton {
      icon: "json"
      text: "Copy settings"
      outlined: true
      Layout.fillWidth: true
      onClicked: {
        var plainData = QtObj2JS.qtObjectToPlainObject(Settings.data);
        var json = JSON.stringify(plainData, null, 2);
        Quickshell.execDetached(["wl-copy", json]);
        ToastService.showNotice("Settings copied to clipboard");
      }
    }
  }
}
