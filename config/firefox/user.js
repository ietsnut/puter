// Firefox, puter's web browser: its own settings. Linked into its default
// profile by install.sh; Firefox reads it at every start, over anything set
// in its preferences page. The look is theme/firefox (puter's stylesheet).

// Read puter's stylesheet (the profile's chrome/userChrome.css).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// labwc's title bar, like every window; the menu bar only on Alt.
user_pref("browser.tabs.inTitlebar", 0);
user_pref("browser.uidensity", 1);
user_pref("browser.toolbars.bookmarks.visibility", "never");
// Downloads at the right of the address field always, as Chrome has it,
// not only once something has been downloaded.
user_pref("browser.download.autohideButton", false);

// Blank pages to start with and in new tabs; nothing restored or suggested.
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);

// Only what's needed: no Pocket, Firefox View, sidebar, AI chat or tab
// previews; no animations.
user_pref("extensions.pocket.enabled", false);
user_pref("browser.tabs.firefox-view", false);
user_pref("sidebar.revamp", false);
user_pref("sidebar.verticalTabs", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.tabs.hoverPreview.enabled", false);
user_pref("ui.prefersReducedMotion", 1);
user_pref("toolkit.cosmeticAnimations.enabled", false);

// Pages light, as every window is.
user_pref("layout.css.prefers-color-scheme.content-override", 1);
