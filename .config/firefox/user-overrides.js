/////////////////////////////////////////////////////////////////////////////////
//                         Personal user.js overrides                          //
/////////////////////////////////////////////////////////////////////////////////

// This file is used to override ghacks' user.js settings, see:
// https://github.com/arkenfox/user.js/wiki/3.3-Updater-Scripts

/* global user_pref */

// 0102: open previous session on startup
user_pref('browser.startup.page', 3);

// 0302a: enable auto-INSTALLING Firefox updates [NON-WINDOWS FF65+]
user_pref('app.update.auto', false);

// 0412: enable Google binary checks
user_pref('browser.safebrowsing.downloads.remote.enabled', true);

// 0807: enable live search suggestions
user_pref('browser.search.suggest.enabled', true);
user_pref('browser.urlbar.suggest.searches', true);

// 1021: enable storing extra session data [SETUP-CHROME]
user_pref('browser.sessionstore.privacy_level', 1);

// 1401: enable websites choosing fonts (0=block, 1=allow)
// Increases exposure to fingerprinting, but disabling it may make websites ugly
// and some PDFs to miss fonts.
user_pref('browser.display.use_document_fonts', 1);

// 2302: enable service workers, required for push notifications and other
//       features.
user_pref('dom.serviceWorkers.enabled', true);

// 2652: add to recent documents list
user_pref('browser.download.manager.addToRecentDocs', false);

// 2803: don't clear stuff when the browser exits
user_pref('privacy.sanitize.sanitizeOnShutdown', false);
user_pref('privacy.clearOnShutdown.cookies', false);
user_pref('privacy.clearOnShutdown.downloads', false);
user_pref('privacy.clearOnShutdown.formdata', false);
user_pref('privacy.clearOnShutdown.history', false);
user_pref('privacy.clearOnShutdown.offlineApps', false);
user_pref('privacy.clearOnShutdown.sessions', false);
user_pref('privacy.clearOnShutdown.siteSettings', false);

// 4501: disable privacy.resistFingerprinting [FF41+]
// This preference seems very important, but it breaks Alt keybindings, even
// ones defined in the "Manage Extension Shortcuts" page. See:
// - https://github.com/arkenfox/user.js/issues/1036
// - https://github.com/arkenfox/user.js/issues/391#issuecomment-486137363
// - https://github.com/tridactyl/tridactyl/issues/1500
// - https://bugzilla.mozilla.org/show_bug.cgi?id=1536533
user_pref('privacy.resistFingerprinting', false);
// 4504: RFP letterboxing [FF67+]
// RFP letterboxing improves anti-fingerprinted by setting the inner page
// dimensions to the closest one from a preset list (800x600, 1600x900, etc.),
// which makes it harder to identify a web client by its page resolution.
// However, this also causes the page window to be smaller than the browser
// window which can be annoying.
user_pref('privacy.resistFingerprinting.letterboxing', false); // [HIDDEN PREF]

// 5000: disable alt key toggling the menu bar [RESTART]
user_pref('ui.key.menuAccessKey', 0);
// 5000: [FF68+] allow userChrome/userContent
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
//
// 1820: enable GMP (Gecko Media Plugins)
// user_pref('media.gmp-widevinecdm.visible', true);
// user_pref('media.gmp-widevinecdm.enabled', true);
// 1830: enable all DRM content (EME: Encryption Media Extension)
// user_pref('media.eme.enabled', true);
//
//
// 2001: enable WebRTC (Web Real-Time Communication)
// Probably needed for some websites, but I don't use them yet, so keeping it
// here just for reference.
// user_pref('media.peerconnection.enabled', true);
//
//
// 2010: enable WebGL (Web Graphics Library)
// user_pref('webgl.disabled', false);
// user_pref('webgl.enable-webgl2', true);
//
// 2022: enable screensharing ***/
// user_pref('media.getusermedia.screensharing.enabled', true);
// user_pref('media.getusermedia.browser.enabled', true);
// user_pref('media.getusermedia.audiocapture.enabled', true);
