# This file contains most of the IPython/Jupyter configuration, except
# names (including imports) that should be available interactively.

# pylint: disable=unused-import

import importlib.util
import os
import pathlib
import re
import socket
import subprocess
import sys
import time
import warnings

import IPython
from IPython import get_ipython

# This startup file is also used by `jupyter console`, which doesn't use prompt
# toolkit, and may fail importing it.
try:
    import prompt_toolkit
    from prompt_toolkit.keys import Keys
    from prompt_toolkit.utils import get_cwidth
    _KeyPressEvent = prompt_toolkit.key_binding.key_processor.KeyPressEvent
except (ImportError, ValueError):
    pass

# Directory with history for multiple hosts
_HIST_DIR = os.path.expanduser(os.path.join('~/.local/var/hist'))
_HIST_FILENAME = 'ipython_hist.sqlite'


# TODO: Look into creating real extensions:
# https://ipython.readthedocs.io/en/stable/config/extensions/
# NOTE: Keep this function in sync with the one in ../10-config.py.
def _load_local_extension(name):
    if '__file__' not in globals():
        warnings.warn('__file__ not set, cannot load IPython local extension')
        return None
    startup_dir = os.path.dirname(__file__)
    while startup_dir and startup_dir != '/':
        if os.path.basename(startup_dir) == 'startup':
            break
        startup_dir = os.path.dirname(startup_dir)
    if not startup_dir or startup_dir == '/':
        warnings.warn('could not detect IPython startup dir')
        return None
    module_path = os.path.join(startup_dir, 'ext', f'{name}.py')
    if not os.path.exists(module_path):
        warnings.warn(f'extension {module_path} not found')
        return None
    spec = importlib.util.spec_from_file_location(name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _run_pip(args):
    # https://ipython.readthedocs.io/en/stable/whatsnew/version7.html#ipython-7-3-0
    if IPython.version_info >= (7, 3, 0):
        get_ipython().run_line_magic('pip', ' '.join(args))
        return
    subprocess.run(['pip'] + args, check=True)


# def _init_file_logging():
#     _BASE_LOG_DIR = os.path.expanduser('~/.local/var/log/ipython')
#     now = time.localtime()
#     date = time.strftime('%Y-%m-%d', now)
#     logdir = os.path.join(_BASE_LOG_DIR, date)
#     log_filename = time.strftime('%H-%M-%S.txt', now)
#     log_filepath = os.path.join(logdir, log_filename)
#     if not os.path.exists(logdir):
#         os.makedirs(logdir)
#     logger = get_ipython().logger
#     logger.logstart(
#         logfname=log_filepath,
#         logmode='rotate',
#         log_output=True,
#         timestamp=True,
#         log_raw_input=True,
#     )
#     print('IPython logfile: {}'.format(log_filepath))


def _is_using_prompt_toolkit():
    return hasattr(get_ipython(), 'pt_app')


def _get_history_files():
    files = []
    this_hostname = socket.gethostname()
    for hostname in sorted(os.listdir(_HIST_DIR)):
        abs_path = os.path.join(_HIST_DIR, hostname, _HIST_FILENAME)
        if not os.path.isfile(abs_path):
            continue
        if hostname == this_hostname:
            files = [abs_path] + files
        else:
            files.append(abs_path)
    return files


# TODO: Implement auto-closing of brackets, quotes, etc. See:
# https://stackoverflow.com/q/57011659/1014208
def _define_prompt_toolkit_keybindings():
    if IPython.version_info[0] < 5:
        warnings.warn(f'Discovered old python version ({IPython.version_info}),'
                      ' not defining keybindings.\n')
        return
    if not _is_using_prompt_toolkit():
        return

    def undo(event: _KeyPressEvent):
        event.current_buffer.undo()

    def redo(event: _KeyPressEvent):
        event.current_buffer.redo()

    def execute_current_commands(event: _KeyPressEvent):
        buff = event.current_buffer
        buff.validate_and_handle()

    def history_backward(event: _KeyPressEvent):
        event.current_buffer.history_backward()

    def history_forward(event: _KeyPressEvent):
        event.current_buffer.history_forward()

    def copy_buffer_to_clipboard(event: _KeyPressEvent):
        copy_to_clipboard(event.current_buffer.text)

    key_bindings = get_ipython().pt_app.key_bindings

    # This only works on version 2. See:
    # https://github.com/jonathanslenders/python-prompt-toolkit/issues/420
    # Bind Ctrl+Enter (equivalent to Ctrl+J) to execute current command.
    key_bindings.add(Keys.ControlJ, filter=True)(execute_current_commands)

    # Bind Alt+_ to undo.
    key_bindings.add(Keys.Escape, '_', filter=True,
                     save_before=lambda x: False)(undo)

    # Bind Alt++ to redo.
    key_bindings.add(Keys.Escape, '+', filter=True,
                     save_before=lambda x: False)(redo)

    key_bindings.add(Keys.ControlP, filter=True)(history_backward)

    key_bindings.add(Keys.ControlN, filter=True)(history_forward)

    key_bindings.add(Keys.ControlQ, 'y', filter=True)(copy_buffer_to_clipboard)

    fzf_history = _load_local_extension('fzf_history')

    def select_history_line(event: _KeyPressEvent):
        return fzf_history.select_history_line(event, _get_history_files())

    if fzf_history:
        key_bindings.add(Keys.ControlR, filter=True)(select_history_line)

    # Make C-o work as operate-and-get-next. See also:
    # https://github.com/jonathanslenders/python-prompt-toolkit/issues/416#issuecomment-391387698
    handler = next(kb.handler
                   for kb in key_bindings.bindings
                   if kb.handler.__name__ in
                   {'newline_autoindent', 'newline_with_copy_margin'})
    key_bindings.remove_binding(handler)


# I store my ipython history in a git repo, and the history saving thread has
# issues in existing ipython sessions after I run inside the history repo:
#   git stash push -- ipython_hist.sqlite && git stash pop
# The error sqlite throws is "attempt to write a readonly database".
def _enable_history_db_recovery():
    # NOTE: I verified that the history_manager exists in IPython 2-8, hopefully
    # this code won't break in future versions.
    hm = get_ipython().history_manager
    if not hm.enabled or hm.hist_file == ':memory:':
        return

    try:
        # pylint: disable-next=import-outside-toplevel
        import sqlite3
    except ImportError:
        warnings.warn('Importing sqlite3 failed, skipping history tweaks')
        return

    # Inherit from sqlite3.Connection because ipython verifies the type
    class AutoReconnect(sqlite3.Connection):

        def __init__(self,
                     conn,
                     extra_connection_opts=None,
                     _my_max_retries=100):
            # if not hasattr(obj, 'db'):
            #     raise ValueError(f'Object {obj} missing "db" attribute')
            # Name all attributes with _my_ prefix to reduce the change of a
            # collision with an existing attribute of the parent class.
            self._my_conn = conn
            self._my_conn_opts = extra_connection_opts
            self._my_num_retries = 0
            self._my_max_retries = _my_max_retries
            self._my_db_input_cache = []

        def __getattribute__(self, name):
            if name.startswith('_my_'):
                return object.__getattribute__(self, name)
            # Store a copy of the input cache so that we can write it to the DB
            # in case of errors.
            hm = get_ipython().history_manager
            # pylint: disable-next=line-too-long
            # history_manager can be set to None at exit?
            # I noticed this error message occasionally:
            #   The history saving thread hit an unexpected error (AttributeError("'NoneType' object has no attribute 'db_input_cache'")).History will not be written to the database.
            if hm:
                self._my_db_input_cache = list(hm.db_input_cache)
            return object.__getattribute__(self._my_conn, name)

        def __exit__(self, exc_type, exc_val, exc_tb):
            result = self._my_conn.__exit__(exc_type, exc_val, exc_tb)
            if not isinstance(exc_val, sqlite3.OperationalError):
                return result
            if self._my_num_retries >= self._my_max_retries:
                warnings.warn(
                    'SQLite returned an error but reached max retries')
                return result
            warnings.warn(
                f'SQLite returned an error, trying to recover: {exc_val}')
            self._my_num_retries += 1
            self._my_conn.close()
            hm = get_ipython().history_manager
            conn_options = dict(hm.connection_options)
            if self._my_conn_opts:
                conn_options.update(self._my_conn_opts)
            self._my_conn = sqlite3.connect(hm.hist_file, **conn_options)
            try:
                with self._my_conn:
                    for line in self._my_db_input_cache:
                        self._my_conn.execute(
                            "INSERT INTO history VALUES (?, ?, ?, ?)",
                            (hm.session_number,) + line)
            except sqlite3.Error:
                print('sqlite error from my config')
                return result
            return True

    # From IPython/core/history.py
    db_init_options = dict(detect_types=sqlite3.PARSE_DECLTYPES |
                           sqlite3.PARSE_COLNAMES)
    db_init_options.update(hm.connection_options)
    hm.db = AutoReconnect(
        hm.db,
        dict(detect_types=sqlite3.PARSE_DECLTYPES | sqlite3.PARSE_COLNAMES))
    hm.save_thread.db = AutoReconnect(hm.save_thread.db, hm.connection_options)


def _register_magic_aliases():
    # Aliases to magics need to be defined using the magics_manager.
    magics_manager = get_ipython().magics_manager
    magics_manager.register_alias('t', 'time')
    magics_manager.register_alias('ti', 'timeit')


# Copied from
# http://stackoverflow.com/questions/7606062/is-there-a-way-to-directly-send-a-python-output-to-clipboard
def copy_to_clipboard(value):
    with subprocess.Popen(['xsel', '--input', '--clipboard'],
                          stdin=subprocess.PIPE) as p:
        p.communicate(input=str(value).encode('utf8'))


def _define_aliases():
    _load_local_extension('shell_aliases')
    _register_magic_aliases()


def _is_ipython_terminal(ipython):
    # Dirty hack to detect if we're running in an IPython terminal, as opposed
    # to Jupyter Notebook/JupyterLab/Qt console.
    # sys.stdout.isatty() also works, but still can't differentiate Jupyter
    # Console from Jupyter Notebook: both return False, although Jupyter Console
    # is connected to a terminal like IPython.
    return type(ipython).__name__ == 'TerminalInteractiveShell'


def _configure_matplotlib():
    try:
        # pylint: disable=import-outside-toplevel
        import matplotlib
        import matplotlib.pyplot as plt
    except ImportError:
        return
    # Enable interactive mode
    # https://matplotlib.org/users/interactive.html#interactive-mode
    plt.ion()
    # NOTE: Some matplotlib backends are only supported in the Jupyter notebook
    # and/or QtConsole, since the IPython terminal shell doesn't support it.
    # Backends with support for Jupyter notebook and JupyterLab [1][2]:
    # - widget: interactive, based on ipympl, possible a bit buggy
    #   As of 2020-09-27, it doesn't show figures automatically, so I'm not
    #   using it.
    # - inline: static images
    # [1] https://matplotlib.org/users/interactive.html#jupyter-notebooks-lab
    # [2] https://ipython.readthedocs.io/en/stable/interactive/plotting.html#rich-outputs
    ipython = get_ipython()
    if _is_ipython_terminal(ipython):
        return
    backend = 'inline'
    # if importlib.util.find_spec('ipympl'):
    #     backend = 'widget'
    # pylint: disable=undefined-variable
    ipython.run_line_magic('matplotlib', backend)
    # NOTE: This is not needed, because matplotlib will default to the Qt
    # backend if it's available:
    # Heuristic to check if the Qt backend is available.
    # elif importlib.util.find_spec('PyQt5'):
    #     get_ipython().run_line_magic('matplotlib', 'qt')


def _configure_completion():
    try:
        # pylint: disable=import-outside-toplevel
        import jedi
    except ImportError:
        return
    jedi.settings.case_insensitive_completion = True
    # In VSCode, adding a bracket causes duplicate completions.
    if _is_using_prompt_toolkit():
        jedi.settings.add_bracket_after_function = True


def _configure_autoreload():
    ipython = get_ipython()
    # Loading autoreload prints a warning that we suppress:
    # "the imp module is deprecated in favour of importlib; see the module's
    # documentation for alternative uses"
    # %reload_ext autoreload
    # pylint: disable=undefined-variable
    ipython.run_line_magic('reload_ext', 'autoreload')
    ipython.run_line_magic('autoreload',
                           3 if IPython.version_info[0] >= 8 else 2)


# https://github.com/deshaw/pyflyby
# https://waylonwalker.com/pyflyby/
def _load_pyflyby():
    ipython = get_ipython()
    try:
        ipython.run_line_magic('load_ext', 'pyflyby')
        return
    except ModuleNotFoundError:
        pass
    try:
        _run_pip(['install', 'pyflyby'])
    except subprocess.CalledProcessError:
        return
    ipython.run_line_magic('load_ext', 'pyflyby')


def _load_rich():
    try:
        # pylint: disable=import-outside-toplevel
        import rich
        import rich.pretty
        import rich.traceback
    except ImportError:
        return
    rich.pretty.install()
    rich.traceback.install()


_define_prompt_toolkit_keybindings()
_enable_history_db_recovery()
_define_aliases()
_configure_matplotlib()
_configure_completion()
_configure_autoreload()
_load_local_extension('autotime')
_load_local_extension('prompt')
_load_pyflyby()
_load_rich()
# Using the %pdb magic prints "Automatic pdb calling has been turned ON"
# which I don't like, so I'm setting it directly on the IPython object.
# %pdb on
# get_ipython().call_pdb = 1
