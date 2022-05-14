/////////////////////////////////////////////////////////////////////////////////
//                         Personal user.js overrides                          //
/////////////////////////////////////////////////////////////////////////////////

// This file is used to override ghacks' user.js settings, see:
// https://github.com/arkenfox/user.js/wiki/3.3-Updater-Scripts

/* global user_pref */

// 0102: open previous session on startup
user_pref('browser.startup.page', 3);

// 0301: enable auto-INSTALLING Firefox updates [NON-WINDOWS]
user_pref('app.update.auto', true);
// 0302: enable auto-INSTALLING Firefox updates via a background service [FF90+] [WINDOWS]
user_pref('app.update.background.scheduling.enabled', true);

// 0403: enable SB checks for downloads with Google (remote)
user_pref('browser.safebrowsing.downloads.remote.enabled', true);
user_pref(
  'browser.safebrowsing.downloads.remote.url',
  'https://sb-ssl.google.com/safebrowsing/clientreport/download?key=%GOOGLE_SAFEBROWSING_API_KEY%'
);

// 0801: enable location bar using search
// This makes it possible to use a search query directly in the address bar
// without prefixing it with "?".
user_pref('keyword.enabled', true);
// 0804: enable live search suggestions
// [NOTE] Both must be true for the location bar to work
// [SETUP-CHROME] Change these if you trust and use a privacy respecting search engine
user_pref('browser.search.suggest.enabled', true);
user_pref('browser.urlbar.suggest.searches', true);
/* 0807: enable location bar contextual suggestions [FF92+]
 * [SETTING] Privacy & Security>Address Bar>Suggestions from...
 * [1] https://blog.mozilla.org/data/2021/09/15/data-and-firefox-suggest/ ***/
user_pref('browser.urlbar.suggest.quicksuggest.nonsponsored', true); // [FF95+]

// 1021: enable storing extra session data [SETUP-CHROME]
user_pref('browser.sessionstore.privacy_level', 0);

// 1401: enable websites choosing fonts (0=block, 1=allow)
// Increases exposure to fingerprinting, but disabling it may make websites ugly
// and some PDFs to miss fonts.
user_pref('browser.display.use_document_fonts', 1);

// 2302: enable service workers, required for push notifications and other
//       features.
user_pref('dom.serviceWorkers.enabled', true);

// 2653: enable adding downloads to the system's "recent documents" list
user_pref('browser.download.manager.addToRecentDocs', true);

// 2801: don't delete cookies and site data on exit
user_pref('network.cookie.lifetimePolicy', 0);
// 2810: disable Firefox to clear items on shutdown (2811)
user_pref('privacy.sanitize.sanitizeOnShutdown', false);
// 2811: set/enforce what items to clear on shutdown (if 2810 is true) [SETUP-CHROME]
user_pref('privacy.clearOnShutdown.cookies', false);
user_pref('privacy.clearOnShutdown.downloads', false);
user_pref('privacy.clearOnShutdown.formdata', false);
user_pref('privacy.clearOnShutdown.history', false);
user_pref('privacy.clearOnShutdown.offlineApps', false);
user_pref('privacy.clearOnShutdown.sessions', false);
user_pref('privacy.clearOnShutdown.siteSettings', false);

// 4501: disable privacy.resistFingerprinting [FF41+]
// [SETUP-WEB] RFP can cause some website breakage: mainly canvas, use a site exception via the urlbar
// This preference seems very important, but it breaks Alt keybindings, even
// ones defined in the "Manage Extension Shortcuts" page. See:
// - https://github.com/arkenfox/user.js/issues/1036
// - https://github.com/arkenfox/user.js/issues/391#issuecomment-486137363
// - https://github.com/tridactyl/tridactyl/issues/1500
// - https://bugzilla.mozilla.org/show_bug.cgi?id=1536533
user_pref('privacy.resistFingerprinting', false);
// 4504: disable RFP letterboxing [FF67+]
// RFP letterboxing improves anti-fingerprinted by setting the inner page
// dimensions to the closest one from a preset list (800x600, 1600x900, etc.),
// which makes it harder to identify a web client by its page resolution.
// However, this also causes the page window to be smaller than the browser
// window which can be annoying.
user_pref('privacy.resistFingerprinting.letterboxing', false); // [HIDDEN PREF]
// 4520: enable WebGL (Web Graphics Library)
// [SETUP-WEB] If you need it then enable it. RFP still randomizes canvas for naive scripts
// NOTE: webgl can be used to fingerprint, but it is pointless to disable it if
// RFP is disabled.
user_pref('webgl.disabled', false);

// 5003: disable saving passwords
user_pref('signon.rememberSignons', false);

// 9000: disable alt key toggling the menu bar [RESTART]
user_pref('ui.key.menuAccessKey', 0);
// 9000: [FF68+] allow userChrome/userContent
// NOTE: this feature can cause issues if Firefox makes changes and the theme is
// not adapted [1], which happened to me a few times with MaterialFox.
// [1] https://github.com/muckSponge/MaterialFox/issues/317
user_pref('toolkit.legacyUserProfileCustomizations.stylesheets', true);
// Required or recommended by by MaterialFox:
// https://github.com/muckSponge/MaterialFox/blob/master/user.js
user_pref('svg.context-properties.content.enabled', true);
user_pref('browser.tabs.tabClipWidth', 83);
// Don't auto-hide tabs and address bar when fullscreen
user_pref('browser.fullscreen.autohide', false);

// Below is stuff that may break websites but I can currently afford to disable.
// If I run into issues, I should try to uncomment these lines, generate the
// user.js again, and see if it's resolved.
// See also: https://github.com/arkenfox/user.js/issues/1080

// 1001: disable disk cache
// [SETUP-CHROME] If you think disk cache helps perf, then feel free to override this
// [NOTE] We also clear cache on exit (2811)
// user_pref('browser.cache.disk.enable', true);
// 1003: disable storing extra session data [SETUP-CHROME]
// define on which sites to save extra session data such as form content, cookies and POST data
// 0=everywhere, 1=unencrypted sites, 2=nowhere
// user_pref('browser.sessionstore.privacy_level', 0);

// 2022: enable all DRM content (EME: Encryption Media Extension)
// user_pref('media.eme.enabled', true);

// 2001: enable WebRTC (Web Real-Time Communication)
// Probably needed for some websites, but I don't use them yet, so keeping it
// here just for reference.
// user_pref('media.peerconnection.enabled', true);

// 2619: use Punycode in Internationalized Domain Names to eliminate possible spoofing
// [SETUP-WEB] Might be undesirable for non-latin alphabet users since legitimate IDN's are also punycoded
// user_pref('network.IDN_show_punycode', false);

// 2620: enable PDFJS scripting [SETUP-CHROME]
// user_pref('pdfjs.enableScripting', true); // [FF86+]
