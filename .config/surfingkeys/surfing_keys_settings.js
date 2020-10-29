// click `Save` button to make above settings to take effect.
// set theme
settings.theme = '\
.sk_theme { \
    background: #fff; \
    color: #000; \
} \
.sk_theme tbody { \
    color: #000; \
} \
.sk_theme input { \
    color: #000; \
} \
.sk_theme .url { \
    color: #555; \
} \
.sk_theme .annotation { \
    color: #555; \
} \
.sk_theme .focused { \
    background: #f0f0f0; \
}';

settings.scrollStepSize = 150;

// Alt-s is already used to split tabs from the current window, use I (shift+i)
// instead.
map('I', '<Alt-s>')
unmap('<Alt-s>')
// map('<Ctrl-i>', '<Alt-s>')

// Alt-p is already used to open lastpass. This unmap command is actually not
// necessary because the lastpass keybinding overrides it (it's defined in
// chrome's extension keybindings), but is here for documentation.
unmap('<Alt-p>')

const defineNavigationMappings = () => {
  aceVimMap(' i', 'i', 'normal');

  // NOTE: The order of mappings matters here- this is similar to map in vim which
  // is notoriously error prone compared to noremap.
  // NOTE: Hebrew mappings are disabled because they seem to work without their
  // definitions below (perhaps the action is determined by the keycode?).
  const navigationMappings = [
    ['i', 'k'],
    // ['ן', 'k'],
    ['k', 'j'],
    // ['ל', 'j'],
    ['j', 'h'],
    // ['ח', 'h'],
  ];

  for (const keys of navigationMappings) {
    map(keys[0], keys[1]);
    imap(keys[0], keys[1]);
    vmap(keys[0], keys[1]);
    cmap(keys[0], keys[1]);
    // for (const mode of ['normal', 'insert', 'visual', 'command']) {
    //   aceVimMap(keys[0], keys[1], mode);
    // }
  }

  unmap('h')
  iunmap('h')
  vunmap('h')
  // cunmap('h')
};

defineNavigationMappings();

map('u', 'e');
