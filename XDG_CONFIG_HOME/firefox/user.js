//mostly url-bar
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.uiCustomization.state", '
{
  "placements": {
    "widget-overflow-fixed-list": [],
    "unified-extensions-area": [
      "passff_invicem_pro-browser-action",
      "idcac-pub_guus_ninja-browser-action"
    ],
    "nav-bar": [
      "back-button",
      "forward-button",
      "stop-reload-button",
      "customizableui-special-spring1",
      "vertical-spacer",
      "urlbar-container",
      "customizableui-special-spring2",
      "downloads-button",
      "passff_invicem_pro-browser-action"
    ],
    "TabsToolbar": [
      "tabbrowser-tabs",
      "new-tab-button",
      "alltabs-button"
    ],
    "vertical-tabs": [],
    "PersonalToolbar": [
      "personal-bookmarks"
    ]
  },
  "seen": [
    "developer-button",
    "passff_invicem_pro-browser-action",
    "idcac-pub_guus_ninja-browser-action",
    "ublock0_raymondhill_net-browser-action",
    "screenshot-button"
  ],
  "dirtyAreaCache": [
    "nav-bar",
    "vertical-tabs",
    "unified-extensions-area"
  ],
  "currentVersion": 23,
  "newElementCount": 2
}
');
user_pref("browser.pageActions.persistedActions", '
    {
      "version": 1,
      "ids": [
        "bookmark",
        "bookmarkSeparator",
        "copyURL",
        "emailLink",
        "sendToDevice",
        "screenshots",
        "pinTab"
      ],
      "idsInUrlbar": []
    }
');
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutConfig.showWarning", false);
user_pref(
    "browser.newtabpage.activity-stream.feeds.section.highlights",
    false
);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("devtools.theme", "dark");
user_pref("identity.fxaccounts.enabled", false);
user_pref("browser.ctrlTab.previews", true);
user_pref("widget.allow-client-side-decoration", true);
user_pref("widget.swipe.success-velocity-contribution", "1");
user_pref("browser.tabs.warnOnClose", false);
user_pref("reader.parse-on-load.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("full-screen-api.warning.timeout", 0);
//user_pref("ui.key.accelKey", 18);
user_pref("ui.key.menuAccessKey", 0);
user_pref("ui.key.menuAccessKeyFocuses", 0);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.override_rfp_for_color_scheme", true);
