import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.ControlCenterV5
import qs.Modules.Panels.Settings
import qs.Services.System
import qs.Services.UI
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  enabled: ProgramCheckerService.wlsunsetAvailable
  icon: Settings.data.nightLight.enabled ? (Settings.data.nightLight.forced ? "nightlight-forced" : "nightlight-on") : "nightlight-off"
  hot: Settings.data.nightLight.enabled
  tooltipText: "Night Light"

  onClicked: {
    if (!Settings.data.nightLight.enabled) {
      Settings.data.nightLight.enabled = true;
      Settings.data.nightLight.forced = false;
    } else if (Settings.data.nightLight.enabled && !Settings.data.nightLight.forced) {
      Settings.data.nightLight.forced = true;
    } else {
      Settings.data.nightLight.enabled = false;
      Settings.data.nightLight.forced = false;
    }
  }

  onRightClicked: {
    SettingsPanelService.openToTab(ControlCenterV5Panel.Tab.Display, -1, screen);
  }
}
