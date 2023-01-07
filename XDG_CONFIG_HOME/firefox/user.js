//mostly url-bar
user_pref("browser.uiCustomization.state", '
    {
      "placements": {
        "widget-overflow-fixed-list": [],
        "PersonalToolbar": [ "personal-bookmarks" ],
        "nav-bar": [ "urlbar-container", "downloads-button" ],
        "TabsToolbar": [ "tabbrowser-tabs", "alltabs-button" ],
        "toolbar-menubar": [ "menubar-items" ]
      },
      "seen": [
        "ublock0_raymondhill_net-browser-action",
        "_46104586-98c3-407e-a349-290c9ff3594d_-browser-action",
        "addon_darkreader_org-browser-action",
        "jid1-kkzogwgsw3ao4q_jetpack-browser-action",
        "developer-button"
      ],
      "dirtyAreaCache": [
        "PersonalToolbar",
        "nav-bar",
        "TabsToolbar",
        "toolbar-menubar"
      ],
      "currentVersion": 12,
      "newElementCount": 0
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
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
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
user_pref("browser.in-content.dark-mode", true);
user_pref("layout.css.prefers-color-scheme.content-override", 2);
user_pref("ui.key.accelKey", 18);
user_pref("ui.key.menuAccessKey", 0);
user_pref("ui.key.menuAccessKeyFocuses", 0);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
