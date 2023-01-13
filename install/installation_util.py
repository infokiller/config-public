#!/usr/bin/env python3
import os
import subprocess
import sys
# pylint: disable=unused-import
from typing import Dict, List, Optional

USER_BIN_DIR = os.path.expanduser('~/.local/bin')
_USER_MAN_DIR = os.path.expanduser('~/.local/share/man')

_VALID_ANSWERS = {'yes': True, 'y': True, 'no': False, 'n': False}
_LINUX_DISTRO_SCRIPT = '/etc/os-release'

log_name = None

def create_user_dirs() -> None:
    os.makedirs(USER_BIN_DIR, exist_ok=True)
    os.makedirs(_USER_MAN_DIR, exist_ok=True)


def symlink_relative(source_path: str, target_path: str) -> str:
    if os.path.lexists(target_path):
        os.remove(target_path)
    target = os.path.dirname(target_path)
    rel_path = os.path.relpath(source_path, target)
    os.symlink(rel_path, target_path)


def get_man_section(path: str) -> int:
    parts = path.split('.')
    section = parts[-1]
    if section == 'gz':
        section = parts[-2]
    return section


def install_man_file(path: str, install_name: str):
    log_info(f'Installing man page {os.path.basename(path)} as {install_name}')
    section_dir = os.path.join(_USER_MAN_DIR, f'man{get_man_section(path)}')
    os.makedirs(section_dir, exist_ok=True)
    symlink_relative(path, os.path.join(section_dir, install_name))


def get_linux_distro() -> str:
    return subprocess.run('. /etc/os-release && printf "%s\n" "${ID}"',
                          shell=True,
                          stdout=subprocess.PIPE,
                          check=True).stdout.decode('utf-8')


def yellow(msg: str) -> str:
    if sys.stdout.isatty() and sys.stderr.isatty():
        return f'\033[33m{msg}\033[0m'
    return msg


def red(msg: str) -> str:
    if sys.stdout.isatty() and sys.stderr.isatty():
        return f'\033[91m{msg}\033[0m'
    return msg


def bold(msg: str) -> str:
    if sys.stdout.isatty() and sys.stderr.isatty():
        return f'\033[1m{msg}\033[0m'
    return msg


def log_info(msg: str) -> None:
    print(f'{log_name}: {msg}')


def log_bold(msg: str) -> None:
    log_info(bold(msg))


def log_warning(msg: str) -> None:
    log_info(yellow(msg))


def read_packages_file(filename: str) -> List[str]:
    this_file_path = os.path.realpath(__file__)
    this_file_dir = os.path.dirname(this_file_path)
    packages_file_path = os.path.join(this_file_dir, filename)
    with open(packages_file_path, encoding='utf-8') as f:
        lines = f.read().splitlines()
    packages = []
    for line in lines:
        line = line.strip()
        if line and line[0] != "#":
            packages.append(line.partition('#')[0].strip())
    return packages


def query_yes_no(question: str, default='yes') -> bool:
    '''Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    '''
    if default is None:
        prompt = ' [y/n] '
    elif default == 'yes':
        prompt = ' [Y/n] '
    elif default == 'no':
        prompt = ' [y/N] '
    else:
        raise ValueError(f'Invalid default answer: "{default}"')

    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == '':
            return _VALID_ANSWERS[default]
        if choice in _VALID_ANSWERS:
            return _VALID_ANSWERS[choice]
        print(f'Please respond with one of: {", ".join(_VALID_ANSWERS)}')
