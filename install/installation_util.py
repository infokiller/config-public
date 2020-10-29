#!/usr/bin/env python3
import os
import subprocess
import sys
# pylint: disable=unused-import
from typing import Dict, List, Optional

USER_BIN_DIR = os.path.expanduser('~/.local/bin')
USER_MAN_DIR = os.path.expanduser('~/.local/share/man/man1')

_VALID_ANSWERS = {'yes': True, 'y': True, 'no': False, 'n': False}
_LINUX_DISTRO_SCRIPT = '/etc/os-release'


def create_user_dirs() -> None:
    if not os.path.exists(USER_BIN_DIR):
        os.makedirs(USER_BIN_DIR)
    if not os.path.exists(USER_MAN_DIR):
        os.makedirs(USER_MAN_DIR)


def symlink_relative(source_path: str, target_path: str) -> str:
    if os.path.lexists(target_path):
        os.remove(target_path)
    target = os.path.dirname(target_path)
    rel_path = os.path.relpath(source_path, target)
    os.symlink(rel_path, target_path)


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


def read_packages_file(filename: str) -> List[str]:
    this_file_path = os.path.realpath(__file__)
    this_file_dir = os.path.dirname(this_file_path)
    packages_file_path = os.path.join(this_file_dir, filename)
    with open(packages_file_path) as f:
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
