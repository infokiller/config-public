# Ultisnips functions that are shared between multiple snippets files. Required
# because global functions are not inherited when extending files, so this is
# the only way to share functions between different snippet files. See:
# https://github.com/SirVer/ultisnips/issues/234

# pylint: disable=import-error
import vim

# Based on:
# https://github.com/wookayin/dotfiles/blob/maste/vim/UltiSnips/python.snippets
def get_ale_lint_codes(linter_name):
    if not vim.eval('get(g:, "ale_enabled", 0) && get(b:, "ale_enabled", 1)'):
        # works only if ALE is installed and enabled
        return ''

    # find all relevant linting (e.g. pylint) codes for the current line
    # ALE does not expose an API for getting all loclist items for the current
    # line.
    all_lints = vim.eval(
        'get(ale#util#FindItemAtCursor(bufnr(""))[0], "loclist")')
    current_line = vim.current.window.cursor[0]

    codes = set()
    for lint in all_lints:
        lnum = int(lint['lnum'])
        if lnum in (current_line,
                    current_line + 1) and lint['linter_name'] == linter_name:
            codes.add(lint['code'])
        elif lnum > current_line:
            # loclist is in an ascending order of line number
            break
    return codes
