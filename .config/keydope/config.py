# pylint: disable=import-error,undefined-variable,invalid-name
#
# For key names see: /usr/include/linux/input-event-codes.h

import re

from keydope import key_parsing
from keydope.keycodes import Key

In = key_parsing.parse_combo_spec
Out = key_parsing.parse_combo

BROWSERS = [
    'firefox',
    'google-chrome',
    'chromium',
    'brave-browser',
    'vivaldi-stable',
    'tor browser',
]
# pylint: disable-next=consider-using-f-string
BROWSERS_RE = re.compile('^({})$'.format('|'.join(BROWSERS)), flags=re.I)

TERMINALS = [
    'kitty',
    'termite',
    'gnome-terminal',
    'terminator',
    'xterm',
    'x-terminal-emulator',
    'urxvt',
    'guake',
    'st',
]
# pylint: disable-next=consider-using-f-string
TERMINALS_RE = re.compile('^({})$'.format('|'.join(TERMINALS)), flags=re.I)

# List of used programs that don't correctly interpret XKB CapsLock/ISO_LEVEL5
# combos:
# - Google Sheets deletes the current cell
# - Qt apps seem to have issues with CapsLock-v
# - Kitty doesn't handle ISO_LEVEL5 correctly:
#   https://github.com/kovidgoyal/kitty/issues/1990
CAPSLOCK_COMBOS_BUGGY_PROGRAMS = BROWSERS + [
    'kitty',
    'copyq',
    'pinentry-qt',
    'calibre',
    'virt-manager',
    'virt-viewer',
    'remote-viewer',
    r'org\.remmina\.Remmina',
    'spicy',
    'xdg-desktop-portal-kde',
]
# pylint: disable-next=consider-using-f-string
CAPSLOCK_COMBOS_BUGGY_PROGRAMS_RE = re.compile('^({})$'.format(
    '|'.join(CAPSLOCK_COMBOS_BUGGY_PROGRAMS)),
                                               flags=re.I)

DEFAULT_CAPSLOCK_MAPPINGS = {
    In('LV5-i'): Out('Up'),
    In('LV5-j'): Out('Left'),
    In('LV5-k'): Out('Down'),
    In('LV5-l'): Out('Right'),
    In('LV5-Shift-i'): Out('Shift-Up'),
    In('LV5-Shift-j'): Out('Shift-Left'),
    In('LV5-Shift-k'): Out('Shift-Down'),
    In('LV5-Shift-l'): Out('Shift-Right'),
    In('LV5-f'): Out('C-f'),
    In('LV5-t'): Out('C-t'),
    In('LV5-u'): Out('C-z'),
    In('LV5-c'): Out('C-c'),
    In('LV5-v'): Out('C-v'),
    In('LV5-M-u'): Out('Ctrl-Shift-z'),
    In('LV5-d'): Out('Ctrl-Backspace'),
    In('LV5-w'): Out('Ctrl-Left'),
    In('LV5-e'): Out('Ctrl-Right'),
    In('LV5-x'): Out('Backspace'),
    In('LV5-q'): Out('Esc'),
    In('LV5-Space'): Out('Enter'),
    In('LV5-M-j'): Out('Home'),
    In('LV5-M-l'): Out('End'),
    In('LV5-M-i'): Out('Page_Up'),
    In('LV5-M-k'): Out('Page_Down'),
    In('LV5-KEY_1'): Out('F1'),
}

TERMINALS_CAPSLOCK_MAPPINGS = {
    In('LV5-d'): Out('C-w'),
    In('LV5-u'): Out('M-Shift-Minus'),
    In('LV5-M-u'): Out('M-Shift-Equal'),
    In('LV5-c'): Out('C-Shift-c'),
    In('LV5-v'): Out('C-Shift-v'),
}

key_processor.define_multipurpose_modmap({
    Key.CAPSLOCK: (Key.ESC, Key.CAPSLOCK, 0.1),
    # This causes Shift+Alt not to work correctly (on a win10 vm the input
    # language is not changed).
    # TODO: fix multipurpose map.
    # Key.LEFT_SHIFT: (Key.KPLEFTPAREN, Key.LEFT_SHIFT, 0.1),
    # Key.RIGHT_SHIFT: (Key.KPRIGHTPAREN, Key.RIGHT_SHIFT, 0.1),
})

# Keybindings for Chromium/Chrome and Firefox, which don't support mapping
# Alt+Semicolon. I'm not sure if Vivaldi, Brave, Edge, and other Chromium-based
# browsers also have this limitation.
key_processor.define_keymap(re.compile(BROWSERS_RE), {
    In('M-Semicolon'): Out('M-Shift-dot'),
}, 'Web browsers')

# Key bindings for non-Chromium web browsers only. Chromium based browsers can
# use the tabctl extension.
# NOTE: tabctl works on Firefox, but Firefox has buggy handling of Alt
# keybindings when RFP is on. See comment in user-overrides.js.
key_processor.define_keymap(
    re.compile('^(firefox|tor browser)$', flags=re.I), {
        In('M-k'): Out('C-page_down'),
        In('M-i'): Out('C-page_up'),
        In('M-Shift-k'): Out('C-Shift-page_down'),
        In('M-Shift-i'): Out('C-Shift-page_up'),
        In('M-j'): Out('Back'),
        In('M-l'): Out('Forward'),
        # Changing the keyboard layout with CapsLock+m causes it to output "m",
        # possibly because it leaks from i3.
        In('LV5-m'): Out('Super-Shift-Insert'),
        # Firefox uses Alt+digit to go to a tab by number, I'm already used to
        # Chrome's Ctrl+digit.
        In('Ctrl-1'): Out('Alt-1'),
        In('Ctrl-2'): Out('Alt-2'),
        In('Ctrl-3'): Out('Alt-3'),
        In('Ctrl-4'): Out('Alt-4'),
        In('Ctrl-5'): Out('Alt-5'),
        In('Ctrl-6'): Out('Alt-6'),
        In('Ctrl-7'): Out('Alt-7'),
        In('Ctrl-8'): Out('Alt-8'),
        In('Ctrl-9'): Out('Alt-9'),
    }, 'Firefox navigation')

# This is a workaround to be able to use Ctrl-w for closing tabs even when using
# another keyboard layout like Chinese. If I try to remap Ctrl-w to itself this
# doesn't work.
# UPDATE 2018-11-29: I fixed this in Chrome using an extension, and I couldn't
# reproduce this in firefox so I'm disabling this for now.
# key_processor.define_keymap(
#     re.compile('Firefox|Google-chrome|Chromium', flags=re.I), {
#         In('C-w'): Out('C-F4'),
#     }, 'Firefox and Chrome close tabs all layouts')

# Termite doesn't support remapping keys.
key_processor.define_keymap(re.compile('^termite$', flags=re.I), {
    In('C-Shift-Minus'): Out('C-Minus'),
    In('C-Shift-0'): Out('C-Equal'),
}, 'Termite zooming')

key_processor.define_keymap(TERMINALS_RE, TERMINALS_CAPSLOCK_MAPPINGS,
                            'Terminal emulators')

# This should be at the end to enable programs to override these keys (since the
# first matching keymap is used).
key_processor.define_keymap(CAPSLOCK_COMBOS_BUGGY_PROGRAMS_RE,
                            DEFAULT_CAPSLOCK_MAPPINGS,
                            'Buggy CapsLock combos programs')

key_processor.define_keymap(
    key_parsing.Condition(device_name_re=re.compile(r'Razer Huntsman Mini')), {
        In('Esc'): Out('Grave'),
        In('Shift-Esc'): Out('Shift-Grave'),
        In('Ctrl-Esc'): Out('Ctrl-Grave'),
        In('Ctrl-Shift-Esc'): Out('Ctrl-Shift-Grave'),
        In('Alt-Esc'): Out('Alt-Grave'),
        In('Alt-Shift-Esc'): Out('Alt-Shift-Grave'),
        In('Super-Esc'): Out('Super-Grave'),
        In('Super-Shift-Esc'): Out('Super-Shift-Grave'),
        # fn+Ctrl+L is translated by the firmware to Ctrl+Right
        In('Ctrl-Right'): Out('Super-Ctrl-L'),
    }, 'Razer Huntsman Mini')
