#!/usr/bin/env python3
"""Shell history stats for new history format."""

import datetime
import errno
import subprocess
import sys

import click
import colored

import history

_ENCODED_NEWLINE = '↵'
_HIGHLIGHTED_ENCODED_NEWLINE = '{}{}{}'.format(
    colored.bg(250) + colored.fg(255), _ENCODED_NEWLINE, colored.attr('reset'))


def extract_command(fzf_output):
    if not fzf_output.strip():
        return ''
    return fzf_output[fzf_output.index('|') + 1:].strip()


_lexer = None
_formatter = None


def _load_pygments():
    global _lexer, _formatter

    import pygments
    import pygments.style
    import pygments.lexers
    import pygments.formatters

    class ZshSyntaxHighlightingStyle(pygments.style.Style):
        default_style = 'tango'

        styles = {
            pygments.token.Comment: 'italic #888',
            pygments.token.Keyword: 'bg: #a80',
            pygments.token.Name.Builtin: '#0c0',
            pygments.token.Literal.String: 'bg: #a80',
            pygments.token.Literal.String.Single: 'bg: #a80',
            pygments.token.Literal.String.Double: 'bg: #a80',
            pygments.token.Name.Function: '#0f0',
            pygments.token.Name.Class: 'bold #0f0',
            pygments.token.String: 'bg:#eee #111'
        }

    _lexer = pygments.lexers.BashLexer()
    _formatter = pygments.formatters.Terminal256Formatter(
        style=ZshSyntaxHighlightingStyle)


def highlight(cmd):
    import pygments
    return pygments.highlight(cmd.strip(), _lexer, _formatter).strip()


def encode_to_selection(cmd, syntax_highlight):
    cmd = cmd.strip()
    if syntax_highlight:
        cmd = highlight(cmd)
    return cmd.replace('\n', _HIGHLIGHTED_ENCODED_NEWLINE)


def decode_from_selection(cmd):
    return cmd.replace(_ENCODED_NEWLINE, '\n')


_DEBUG_MODE = False


def _set_debug_mode(ctx, param, value):
    global _DEBUG_MODE
    _DEBUG_MODE = value


def _log_with_time(text):
    if _DEBUG_MODE:
        print('{}: {}'.format(datetime.datetime.now().strftime('%H:%M:%S.%f'),
                              text))


def send_entries_to_fzf(entries, expand_commands, syntax_highlight, fzf):
    # Importing pygments is very slow (~0.3 seconds), so we only do it here if
    # requested.
    if syntax_highlight:
        _load_pygments()

    for entry in reversed(entries):
        if expand_commands:
            cmd = entry.executed_command
        else:
            cmd = entry.typed_command
        cmd = encode_to_selection(cmd, syntax_highlight)
        line = '{:%Y-%m-%d %H:%M:%S} | {}\n'.format(entry.invocation_time,
                                                    cmd).encode('utf-8')
        try:
            fzf.stdin.write(line)
        except IOError as e:
            if e.errno == errno.EPIPE:
                _log_with_time('Breaking after broken pipe')
                return
    _log_with_time('Done outputting entries')


@click.command()
@click.option('--debug',
              default=False,
              is_flag=True,
              callback=_set_debug_mode,
              is_eager=True,
              help='Debug mode.')
@click.option('--initial-query',
              default='',
              help='Initial query for filtering.')
@click.option('--max-entries',
              default=30000,
              help='Maximum history entries to consider.')
@click.option('--syntax-highlight',
              default=False,
              is_flag=True,
              help='Apply syntax highlighting.')
@click.option('--use-new-history-file',
              default=False,
              is_flag=True,
              help='Use new csv history file')
@click.option('--expand-commands',
              default=False,
              is_flag=True,
              help='Show stats about the executed commands, not the typed ones.'
             )
def main(debug, use_new_history_file, expand_commands, syntax_highlight,
         max_entries, initial_query):
    # Workaround for some strange issue when I'm running outside tmux.
    # Update 2018-10-21: This caused an issue when running from a shell spawned
    # from a firejailed ranger, and I can't reproduce the original issue that
    # lead to this workaround, so I'm just disabling it.
    # stderr_file = subprocess.PIPE if 'TMUX' in os.environ else None
    stderr_file = None
    _log_with_time('Starting fzf')
    fzf = subprocess.Popen([
        'fzf-tmux',
        '--no-sort',
        '--multi',
        '-n3..,..',
        '--tiebreak=index',
        '--ansi',
        '--bind=ctrl-r:toggle-sort',
        '--exact',
        '--query={}'.format(initial_query),
    ],
                           stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE,
                           stderr=stderr_file)
    _log_with_time('Starting parsing')
    if use_new_history_file:
        entries = history.parse_history_v3(max_entries)
    else:
        entries = history.parse_history_v2(max_entries)
    _log_with_time('Done parsing')
    send_entries_to_fzf(entries, expand_commands, syntax_highlight, fzf)
    _log_with_time('Done outputting to fzf')
    stdout, stderr = fzf.communicate()
    _log_with_time('Got selection from fzf')
    if fzf.returncode == 0:
        lines = []
        for line in stdout.decode('utf-8').split('\n'):
            if not line.strip():
                continue
            lines.append(decode_from_selection(extract_command(line)))
        print('\n'.join(lines))
    # The 130 error code is when the user exited fzf, which is not an error.
    elif fzf.returncode != 130:
        sys.stderr.write(str(stderr))
    _log_with_time('Done')


if __name__ == '__main__':
    _log_with_time('Before main')
    main()
    _log_with_time('After main')
