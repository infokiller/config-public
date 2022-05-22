# Configure IPython's prompt, see also:
# https://waylonwalker.com/custom-ipython-prompt/
# https://blog.paynepride.com/ipython-prompt/
# https://github.com/javidcf/ipython_venv_path_prompt
import os
import pathlib
import re
import subprocess
import sys
import warnings

import IPython
from IPython import get_ipython

# This startup file is also used by `jupyter console`, which doesn't use prompt
# toolkit, and may fail importing it.
try:
    from IPython.terminal.prompts import Prompts, Token
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


def get_conda_env():
    conda_env = os.getenv('CONDA_DEFAULT_ENV', '')
    m = re.match(r'.*/conda/envs/([^/]+)$', sys.prefix)
    if not m:
        return conda_env
    conda_env_from_prefix = m.groups()[0]
    if conda_env and conda_env != conda_env_from_prefix:
        warnings.warn(
            f'Inconsistent conda env: CONDA_DEFAULT_ENV = {conda_env}, '
            f'sys.prefix = {sys.prefix}')
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


class MyPrompt(Prompts):

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
            (Token, '\n'),
            (
                Token.Prompt if self.shell.last_execution_succeeded else
                Token.Generic.Error,
                '❯ ',
            ),
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
