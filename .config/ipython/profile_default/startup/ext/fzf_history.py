# pylint: disable=import-outside-toplevel
# pylint: disable=global-statement

import datetime
import errno
import os
import sqlite3
import subprocess
import sys
import tempfile
import threading
from typing import Any, Callable, Generator, Tuple

import IPython

# This startup file is also used by `jupyter console`, which doesn't use prompt
# toolkit, and may fail importing it.
try:
    import prompt_toolkit
    from prompt_toolkit.keys import Keys
    _KeyPressEvent = prompt_toolkit.key_binding.key_processor.KeyPressEvent
except (ImportError, ValueError):
    pass

_ENCODED_NEWLINE = '↵'
_ENCODED_NEWLINE_HIGHLIGHT = '\x1b[48;5;250m\x1b[38;5;255m'
_ENCODED_NEWLINE_HIGHLIGHT_RESET = '\x1b[0m'
_HIGHLIGHTED_ENCODED_NEWLINE = '{}{}{}'.format(
    _ENCODED_NEWLINE_HIGHLIGHT, _ENCODED_NEWLINE,
    _ENCODED_NEWLINE_HIGHLIGHT_RESET)

_FZF_PREVIEW_SCRIPT = '''
echo {+n} > "%s"
cat -- "%s"
'''

_PYGMENTS_LEXER = None
_PYGMENTS_STYLE = None
_PYGMENTS_FORMATTER = None

# Time the entry was executed and the code executed.
HistoryEntry = Tuple[datetime.datetime, str]


def _load_pygments_objects():
    import pygments
    global _PYGMENTS_LEXER, _PYGMENTS_STYLE, _PYGMENTS_FORMATTER
    try:
        _PYGMENTS_LEXER = pygments.lexers.get_lexer_by_name('ipython3')
    except pygments.lexers.ClassNotFound:
        _PYGMENTS_LEXER = pygments.lexers.get_lexer_by_name('python3')
    try:
        _PYGMENTS_STYLE = pygments.styles.get_style_by_name('solarized-dark')
    except pygments.styles.ClassNotFound:
        _PYGMENTS_STYLE = pygments.styles.get_style_by_name('default')
    try:
        _PYGMENTS_FORMATTER = pygments.formatters.get_formatter_by_name(
            'terminal16m', style=_PYGMENTS_STYLE)
    except pygments.formatters.ClassNotFound:
        _PYGMENTS_STYLE = pygments.formatters.get_formatter_by_name(
            'terminal256', style=_PYGMENTS_STYLE)


def _highlight_code(code: str) -> str:
    import pygments
    global _PYGMENTS_LEXER, _PYGMENTS_STYLE, _PYGMENTS_FORMATTER
    if _PYGMENTS_LEXER is None:
        _load_pygments_objects()
    return pygments.highlight(code, _PYGMENTS_LEXER, _PYGMENTS_FORMATTER)


class _HistoryPreviewThread(threading.Thread):

    def __init__(self, fifo_input_path: str, fifo_output_path: str,
                 history_getter: Callable[[int], Any], **kwargs):
        super().__init__(**kwargs)
        self.fifo_input_path = fifo_input_path
        self.fifo_output_path = fifo_output_path
        self.history_getter = history_getter
        self.is_done = threading.Event()

    def run(self) -> None:
        while not self.is_done.is_set():
            with open(self.fifo_input_path) as fifo_input:
                while not self.is_done.is_set():
                    data = fifo_input.read()
                    if len(data) == 0:
                        break
                    indices = [int(s) for s in data.split()]
                    entries = [self.history_getter(i)[1] for i in indices]
                    code = '\n\n'.join(entries)
                    highlighted_code = _highlight_code(code)
                    with open(self.fifo_output_path, 'w') as fifo_output:
                        fifo_output.write(highlighted_code)

    def stop(self):
        self.is_done.set()
        with open(self.fifo_input_path, 'w') as f:
            f.close()
        self.join()


def _extract_command(fzf_output):
    if not fzf_output.strip():
        return ''
    return fzf_output[fzf_output.index('|') + 1:].strip()


def _encode_to_selection(code: str) -> str:
    code = code.strip()
    return code.replace('\n', _HIGHLIGHTED_ENCODED_NEWLINE)


def _decode_from_selection(code: str) -> str:
    return code.replace(_ENCODED_NEWLINE, '\n')


def _send_entry_to_fzf(entry: HistoryEntry, fzf):
    code = _encode_to_selection(entry[1])
    line = '{:%Y-%m-%d %H:%M:%S} | {}\n'.format(entry[0], code).encode('utf-8')
    try:
        fzf.stdin.write(line)
    except IOError as e:
        if e.errno == errno.EPIPE:
            return


def _create_preview_fifos():
    fifo_dir = tempfile.mkdtemp(prefix='ipython_fzf_hist_')
    fifo_input_path = os.path.join(fifo_dir, 'input')
    fifo_output_path = os.path.join(fifo_dir, 'output')
    os.mkfifo(fifo_input_path)
    os.mkfifo(fifo_output_path)
    return fifo_input_path, fifo_output_path


def _create_fzf_process(initial_query, fifo_input_path, fifo_output_path):
    return subprocess.Popen([
        'fzf-tmux',
        '--no-sort',
        '--multi',
        '-n3..,..',
        '--tiebreak=index',
        '--ansi',
        '--bind=ctrl-r:toggle-sort',
        '--exact',
        '--query={}'.format(initial_query),
        '--preview={}'.format(_FZF_PREVIEW_SCRIPT %
                              (fifo_input_path, fifo_output_path)),
    ],
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE)


def _get_history_from_connection(con) -> Generator[HistoryEntry, None, None]:
    session_to_start_time = {}
    for session, start_time in con.execute(
            'SELECT session, start FROM sessions'):
        session_to_start_time[session] = start_time
    query = '''
    SELECT session, source_raw FROM (
        SELECT session, source_raw, rowid FROM history ORDER BY rowid DESC
    )
    '''
    for session, source_raw in con.execute(query):
        yield (session_to_start_time[session], source_raw)


def _get_command_history(files=None) -> Generator[HistoryEntry, None, None]:
    hist_manager = IPython.get_ipython().history_manager
    if not files:
        files = [hist_manager.hist_file]
    for file in files:
        # detect_types causes timestamps to be returned as datetime objects.
        con = sqlite3.connect(file,
                              detect_types=sqlite3.PARSE_DECLTYPES |
                              sqlite3.PARSE_COLNAMES,
                              **hist_manager.connection_options)
        for entry in _get_history_from_connection(con):
            yield entry
        con.close()


def select_history_line(event: _KeyPressEvent, history_files=None):
    fifo_input_path, fifo_output_path = _create_preview_fifos()
    fzf = _create_fzf_process(event.current_buffer.text, fifo_input_path,
                              fifo_output_path)
    history = []
    preview_thread = _HistoryPreviewThread(fifo_input_path, fifo_output_path,
                                           lambda i: history[i])
    preview_thread.start()
    for entry in _get_command_history(history_files):
        history.append(entry)
        _send_entry_to_fzf(entry, fzf)
    stdout, stderr = fzf.communicate()
    preview_thread.stop()
    if fzf.returncode == 0:
        lines = []
        for line in stdout.decode('utf-8').split('\n'):
            if not line.strip():
                continue
            lines.append(_decode_from_selection(_extract_command(line)))
        event.current_buffer.document = prompt_toolkit.document.Document(
            '\n'.join(lines))
    # The 130 error code is when the user exited fzf, which is not an error.
    elif fzf.returncode != 130:
        sys.stderr.write(str(stderr))


def _is_using_prompt_toolkit():
    return hasattr(IPython.get_ipython(), 'pt_app')


if _is_using_prompt_toolkit():
    key_bindings = IPython.get_ipython().pt_app.key_bindings
    key_bindings.add(Keys.ControlR, filter=True)(select_history_line)
