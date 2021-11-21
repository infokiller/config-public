#!/usr/bin/env python3
# pylint: disable=invalid-name

import logging
import logging.handlers
import subprocess
import sys

import pytimeparse

PRESET_DURATIONS = ['30m', '1h30m', '3h', '24h']
UNSUSPEND_SCREENLOCK_UNIT = 'unsuspend-screenlock'
_LOG_FMT = '%(asctime)s %(levelname)s [%(filename)s:%(lineno)d] %(message)s'


def _init_logger():
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
    stdout_handler = logging.StreamHandler()
    formatter = logging.Formatter(_LOG_FMT)
    syslog_handler.setFormatter(formatter)
    stdout_handler.setFormatter(formatter)
    logger.addHandler(syslog_handler)
    logger.addHandler(stdout_handler)
    logger.info('Starting script %s', __file__)
    return logger


# pylint: disable=invalid-name
_logger = _init_logger()


def _exit_with_error(error):
    subprocess.run([
        'notify-send', '--urgency=critical', 'suspend-screenlock failure', error
    ],
                   check=False)
    sys.exit(error)


def _prompt_suspend_duration() -> int:
    cmd = [
        'rofi', '-dmenu', '-theme-str',
        f'window {{width: 30ch;}} listview {{lines: {len(PRESET_DURATIONS)};}}'
    ]
    completed_process = subprocess.run(cmd,
                                       check=False,
                                       encoding='utf-8',
                                       input='\n'.join(PRESET_DURATIONS),
                                       text=True,
                                       stdout=subprocess.PIPE)
    # User cancelled the selection.
    if completed_process.returncode == 1:
        sys.exit(1)
    seconds = pytimeparse.parse(completed_process.stdout)
    if not seconds:
        _exit_with_error(f'Invalid duration string: {completed_process.stdout}')
    return seconds


def _schedule_screenlock_restart(seconds: int):
    subprocess.run([
        'systemctl', '--user', 'stop',
        '{}.timer'.format(UNSUSPEND_SCREENLOCK_UNIT)
    ],
                   check=False)
    screenlock_restart_cmd = [
        'systemd-run', '--user', '--on-active={}'.format(int(seconds)),
        '--unit={}'.format(UNSUSPEND_SCREENLOCK_UNIT), 'systemctl', '--user',
        'start', 'screenlock-daemon'
    ]
    screenlock_restart = subprocess.run(screenlock_restart_cmd,
                                        stderr=subprocess.PIPE,
                                        check=False)
    if screenlock_restart.returncode != 0:
        _exit_with_error('Could not schedule restart of screenlock: {}'.format(
            screenlock_restart.stderr.decode('utf-8')))


def _stop_screenlock():
    screenlock_stop = subprocess.run(
        ['systemctl', '--user', 'stop', 'screenlock-daemon'],
        stderr=subprocess.PIPE,
        check=False)
    if screenlock_stop.returncode != 0:
        _exit_with_error('Could not stop screenlock daemon: {}'.format(
            screenlock_stop.stderr.decode('utf-8')))


def main():
    seconds = _prompt_suspend_duration()
    _logger.info('Scheduling restart of screenlock daemon')
    _schedule_screenlock_restart(seconds)
    _logger.info('Stopping screenlock daemon service')
    _stop_screenlock()
    _logger.info('Decreasing monitor power saving')
    subprocess.run(['xset', 'dpms', '5400', '5400', '5400'], check=False)


if __name__ == '__main__':
    main()
