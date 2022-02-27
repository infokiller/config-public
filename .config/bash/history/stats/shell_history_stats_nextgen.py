#!/usr/bin/env python3
"""Shell history stats for new history format."""
import datetime
import pathlib
import sys

import click
import history

from stats import shell_history_stats_util


@click.command()
@click.option(
    '--min-date',
    default='2017-03-11',
    help='Only commands after this date are considered. Example: 2017-01-30')
@click.option(
    '--max-date',
    default='2100-01-01',
    help='Only commands before this date are considered. Example: 2017-01-30')
@click.option('--expand-commands',
              default=False,
              is_flag=True,
              help='Show stats about the executed commands, not the typed ones.'
             )
def main(min_date, max_date, expand_commands):
    min_date = datetime.datetime.strptime(min_date, '%Y-%m-%d')
    max_date = datetime.datetime.strptime(max_date, '%Y-%m-%d')
    entries = history.parse_history_v3()
    entries = [
        e for e in entries
        if e.invocation_time >= min_date and e.invocation_time <= max_date
    ]
    if not entries:
        print('No entries found')
        return
    print('First history entry:\n{}'.format(entries[0]))
    print('-' * 80)
    if expand_commands:
        print('Executed commands stats:')
        cmds = [e.executed_command for e in entries]
    else:
        print('Typed commands stats:')
        cmds = [e.typed_command for e in entries]
    shell_history_stats_util.compute_all_stats(cmds)


if __name__ == '__main__':
    main()
