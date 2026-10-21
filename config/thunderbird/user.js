// Thunderbird, puter's mail: its own settings. Linked into its default
// profile by install.sh; Thunderbird reads it at every start, over anything
// set in its settings. The look is theme/thunderbird (puter's stylesheet).

// Read puter's stylesheet (the profile's chrome/userChrome.css).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// labwc's title bar, like every window. The message list's rows are
// ceil(font size × 1.4) + 7px at normal density (about3Pane.js, which
// scrolls by that height): 16 makes them one 30px module. The stylesheet
// keeps the text itself at puter's 15px.
user_pref("mail.tabs.drawInTitlebar", false);
user_pref("mail.uidensity", 1);
user_pref("mail.uifontsize", 16);

// Three columns: the folders, the message list as a table (one message a
// row, not cards; threads off) and the message.
user_pref("mail.threadpane.listview", 1);
user_pref("mailnews.default_view_flags", 0);
user_pref("mail.pane_config.dynamic", 2);

// No start page, default-client nag, donation or news popups, chat or
// Thundermail sign-in; nothing reported.
user_pref("mailnews.start_page.enabled", false);
user_pref("mail.shell.checkDefaultClient", false);
user_pref("mail.inappnotifications.enabled", false);
user_pref("app.donation.eoy.version.viewed", 999);
user_pref("mail.chat.enabled", false);
user_pref("mail.thundermail.enabled", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("app.update.auto", false);

// New mail as a toast (the shell's notifications), no sound; no animations.
user_pref("mail.biff.show_alert", true);
user_pref("mail.biff.use_system_alert", true);
user_pref("mail.biff.play_sound", false);
user_pref("ui.prefersReducedMotion", 1);
user_pref("toolkit.cosmeticAnimations.enabled", false);

// Plain-text mail in the sans, like everything else.
user_pref("mail.fixed_width_messages", false);

// Mail and windows light, as every window is.
user_pref("layout.css.prefers-color-scheme.content-override", 1);
user_pref("browser.theme.toolbar-theme", 1);
user_pref("browser.theme.content-theme", 1);
