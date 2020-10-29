# pylint: disable=invalid-name
import os
import re

import IPython

# Aliases to remap to avoid confusion.
_ALIAS_REMAP = {
    # Browser
    'b': 'browser',
}

# Aliases that are either not working, meaningless or are confusing to use
# inside ipython.
_ALIAS_BLACKLIST = [
    'alert',
    'c',
    'd',
    'e',
    'f1',
    'f2',
    'f3',
    'f4',
    'f5',
    'ipy',
    'j',
    'j1',
    'j2',
    'j3',
    'j4',
    'j5',
    'jl',
    'k1',
    'k2',
    'k3',
    'k4',
    'k5',
    'le',
    'o',
    'p',
    'px',
    'sc',
    't',
    'tt',
    'u',
    '2u',
    '3u',
    '4u',
    '5u',
    'u1',
    'u2',
    'u3',
    'u4',
    'u5',
    'uu',
    'v',
    'xc',
    'y',
    'yank',
    'EX',
]

_REPO_ROOT = os.path.normpath(
    os.path.join(os.path.dirname(__file__), '../../../../../'))
_ALIASES_FILE = f'{_REPO_ROOT}/.config/bash/functions.sh'

# We can't execute aliases directly because recursive aliases won't work. For
# example I have an `ll` alias that references an `l` alias, but when executing
# `ll` in ipython, it complains about no `l` command.
# NOTE: without suing eval the command below doesn't work for some reason with
# `-c` (but it does work in a script)
_BASH_COMMANDS = [
    f'source \"{_ALIASES_FILE}\"', 'shopt -s expand_aliases', 'eval "{} %l"'
]
_EXECUTE_ALIAS_TEMPLATE = f"bash -c '{';'.join(_BASH_COMMANDS)}'"


def _execute_alias_command(alias):
    return _EXECUTE_ALIAS_TEMPLATE.format(alias)


def _copy_shell_aliases():
    quotes = '"\''
    bash_aliases = os.popen(
        f"bash -l -c 'source {_ALIASES_FILE} && alias'").read().splitlines()
    # Valid chars in alias names: https://unix.stackexchange.com/a/168222/126543
    alias_regex = re.compile(r'alias\s*([a-zA-Z0-9_@!,%-]+)=(.+)')
    for alias in bash_aliases:
        regex_match = alias_regex.match(alias)
        if not regex_match:
            continue
        name, command = regex_match.groups()
        if name in _ALIAS_BLACKLIST or '%l' in command:
            continue
        name = _ALIAS_REMAP.get(name, name)
        begin, end = 0, len(command)
        if command[0] in quotes:
            begin += 1
        if command[-1] in quotes:
            end -= 1
        command = command[begin:end]
        # Escape sequences for arguments.
        command = command.replace('%s', '%%s')
        if command:
            IPython.get_ipython().alias_manager.define_alias(
                name, _execute_alias_command(command))


_copy_shell_aliases()
