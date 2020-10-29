#!/usr/bin/env python3
import collections
import operator
import sys

import tabulate

_UNIT_TO_SECONDS_MULTIPLER = {
    's': 1,
    'm': 60,
    'h': 60 * 60,
}

MAX_PRINTED_CMD_LENGTH = 20


def shorten_cmd(cmd, max_length):
    if len(cmd) <= max_length:
        return cmd
    n = max_length // 2 - 2
    return '{}...{}'.format(cmd[:n], cmd[-n:])


def token_to_seconds(token):
    return _UNIT_TO_SECONDS_MULTIPLER[token[-1]] * int(token[:-1])


def main():
    cmd_to_total_seconds = collections.defaultdict(int)
    for line in sys.stdin:
        # print (line)
        cmd, _, duration_string = line.partition(', ')
        duration_seconds = sum(
            token_to_seconds(t) for t in duration_string.split())
        # print (cmd, duration_string, duration_seconds)
        cmd_to_total_seconds[cmd] += duration_seconds
    cmd_total_seconds = list(cmd_to_total_seconds.items())
    cmd_total_seconds.sort(key=operator.itemgetter(1), reverse=True)
    cmd_duration_to_output = []
    for cmd, seconds in cmd_total_seconds:
        duration_str = '{:.1f} hours'.format(seconds / (60 * 60))
        cmd_duration_to_output.append(
            (shorten_cmd(cmd, MAX_PRINTED_CMD_LENGTH), duration_str))
    print(tabulate.tabulate(cmd_duration_to_output))


if __name__ == "__main__":
    main()
