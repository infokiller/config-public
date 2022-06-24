# Configure IPython's prompt, see also:
# https://waylonwalker.com/custom-ipython-prompt/
# https://blog.paynepride.com/ipython-prompt/
# https://github.com/javidcf/ipython_venv_path_prompt
import functools
import os
import pathlib
import re
import subprocess
import sys
import time
import warnings

import IPython
from IPython import get_ipython

# This startup file is also used by `jupyter console`, which doesn't use prompt
# toolkit, and may fail importing it.
try:
    from IPython.terminal.prompts import Prompts, Token
    from prompt_toolkit.enums import EditingMode
    from prompt_toolkit.key_binding import vi_state
    from prompt_toolkit.utils import get_cwidth
except (ImportError, ValueError):
    # Required for the class definition below to not fail.
    Prompts = object


def _is_ipython_terminal(ipython):
    # Dirty hack to detect if we're running in an IPython terminal, as opposed
    # to Jupyter Notebook/JupyterLab/Qt console.
    # sys.stdout.isatty() also works, but still can't differentiate Jupyter
    # Console from Jupyter Notebook: both return False, although Jupyter Console
    # is connected to a terminal like IPython.
    return type(ipython).__name__ == 'TerminalInteractiveShell'


def _is_using_prompt_toolkit():
    return hasattr(get_ipython(), 'pt_app')


_warned_inconsistent_env = 0


def get_conda_env():
    # pylint: disable-next=global-statement
    global _warned_inconsistent_env
    conda_env = os.getenv('CONDA_DEFAULT_ENV', '')
    m = re.match(r'.*/conda/envs/([^/]+)$', sys.prefix)
    if not m:
        return conda_env
    conda_env_from_prefix = m.groups()[0]
    if conda_env and conda_env != conda_env_from_prefix and (
            not _warned_inconsistent_env):
        warnings.warn(
            f'Inconsistent conda env: CONDA_DEFAULT_ENV = {conda_env}, '
            f'sys.prefix = {sys.prefix}')
        _warned_inconsistent_env = 1
    return conda_env_from_prefix


# Returns the virtual env name for venv/virtualenv
def get_venv_env():
    # https://stackoverflow.com/a/1883251/1014208
    # https://stackoverflow.com/a/58026969/1014208
    if hasattr(sys, 'real_prefix') or (sys.base_prefix and
                                       sys.base_prefix != sys.prefix):
        return pathlib.Path(sys.prefix).parts[-1]
    return ''


# https://github.com/javidcf/ipython_venv_path_prompt/blob/master/ipython_venv_path_prompt/ipython_venv_path_prompt.py#L9
def get_virtual_env():
    conda_env = get_conda_env()
    venv_env = get_venv_env()
    if venv_env:
        if conda_env and conda_env != venv_env:
            return f'[{conda_env}][{venv_env}]'
        return venv_env
    return conda_env


def get_displayed_path():
    cols = IPython.utils.terminal.get_terminal_size().columns
    if cols < 10:
        return ''
    cwd = pathlib.Path.cwd().absolute()
    home = pathlib.Path.home()
    if cwd == home:
        return '~'
    if cwd.as_posix().startswith(home.as_posix()):
        path = pathlib.Path('~', cwd.relative_to(home))
    else:
        path = cwd
    if get_cwidth(path.as_posix()) < 30 and cols > 40:
        return path.as_posix()
    parts = [path.parts[0]] + [p[0] for p in path.parts[1:-2]] + list(
        path.parts[-2:])
    return pathlib.Path(*parts).as_posix()


# pylint: disable-next=unused-variable
def get_git_branch():
    try:
        return subprocess.check_output(
            'git branch --show-current', shell=True,
            stderr=subprocess.DEVNULL).decode('utf-8').replace('\n', '')
    except subprocess.CalledProcessError:
        return ''


_VI_INPUT_MODE_TO_DISPLAYED = {
    'vi-insert': 'I',
    'vi-insert-multiple': 'M',
    # Normal mode.
    'vi-navigation': 'N',
    'vi-replace': 'R',
    'vi-replace-single': 'r',
}


# See also:
# https://github.com/ipython/ipython/commit/ee3eebcc0768f845f00a516296959438fdb32384
def get_vi_input_mode_str(shell):
    if (getattr(shell.pt_app, 'editing_mode', None) != EditingMode.VI or
            not shell.prompt_includes_vi_mode):
        return None
    mode = shell.pt_app.app.vi_state.input_mode
    if isinstance(mode, vi_state.InputMode):
        return mode.value
    assert isinstance(mode, str)
    return mode


_BYTES_SUFFIX = [
    (1024**0, 'b'),
    (1024**1, 'K'),
    (1024**2, 'M'),
    (1024**3, 'G'),
    (1024**4, 'T'),
]


def _format_num_bytes(num_bytes):
    for scaling, suffix in _BYTES_SUFFIX[:-1]:
        if num_bytes < 1024 * scaling:
            return f'{num_bytes/scaling:.1f}{suffix}'
    scaling, suffix = _BYTES_SUFFIX[-1]
    return f'{num_bytes/scaling:.1f}{suffix}'


def _cache_with_ttl(max_ttl):

    def _decorator_cache_with_timeout(func):

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            now = time.time()
            if hasattr(wrapper,
                       'cached_result') and (now - wrapper.last_call < max_ttl):
                return wrapper.cached_result
            wrapper.last_call = now
            wrapper.cached_result = func(*args, **kwargs)
            return wrapper.cached_result

        wrapper.last_call = 0

        return wrapper

    return _decorator_cache_with_timeout


class MyPrompt(Prompts):

    def __init__(self, shell):
        super().__init__(shell)
        self.pid = os.getpid()
        try:
            # pylint: disable-next=import-outside-toplevel
            import psutil
            self._process = psutil.Process(self.pid)
        except ImportError:
            warnings.warn('psutil not installed, falling back to cli')
            self._process = None

    # TODO: Add support for adding info to the right hand side of the prompt.
    @_cache_with_ttl(10)
    def get_process_rss(self):
        if self._process:
            return self._process.memory_info().rss
        try:
            ps = subprocess.run(['ps', '-o', 'rss=', '-p',
                                 str(self.pid)],
                                capture_output=True,
                                universal_newlines=True,
                                check=True,
                                timeout=0.1)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return None
        # ps returns the result in kilobytes
        return 1024 * int(ps.stdout)

    def _get_vi_mode_tokens(self):
        mode = _VI_INPUT_MODE_TO_DISPLAYED.get(get_vi_input_mode_str(
            self.shell))
        if not mode:
            return []
        return [(Token.Prompt, f'{mode} ')]

    def _get_input_prompt_tokens(self):
        tokens = self._get_vi_mode_tokens()
        style = Token.Prompt
        if not self.shell.last_execution_succeeded:
            style = Token.Generic.Error
        tokens.append((style, '❯ '))
        return tokens

    def in_prompt_tokens(self):
        venv = get_virtual_env()
        venv_tokens = [
            (Token, ' '),
            (Token.Keyword, venv),
            # (Token.Prompt, ' '),
        ] if venv else []
        path = get_displayed_path()
        path_tokens = [
            (Token, ' '),
            (Token.String.Literal, path),
        ] if path else []
        rss = self.get_process_rss()
        rss_tokens = [
            (Token, ' '),
            (Token.Operator, _format_num_bytes(rss)),
        ] if rss and rss > 1024**3 else []
        # ver = platform.python_version_tuple()
        return [
            # (Token.Name.Class, f'Py v{ver[0]}.{ver[1]}'),
            # (Token, ' '),
            # (Token.Generic.Subheading, '↪'),
            # (Token.Generic.Subheading, get_git_branch()),
            # (Token, ' '),
            (Token.Keyword, ''),
            *venv_tokens,
            *path_tokens,
            *rss_tokens,
            (Token, '\n'),
            *self._get_input_prompt_tokens(),
        ]


def main():
    if IPython.version_info[0] < 5:
        warnings.warn(f'Discovered old python version ({IPython.version_info}),'
                      ' not configuring prompt.\n')
        return
    if not _is_ipython_terminal(get_ipython()) or not _is_using_prompt_toolkit:
        return
    get_ipython().prompts = MyPrompt(get_ipython())


main()
