"""History parsing."""
from __future__ import annotations

import csv
import datetime
import io
import os
import socket

HIST_V2_DIR = os.path.expanduser('~/.local/var/hist')
HIST_V2_FILENAME = 'persistent_shell_history_nextgen'
HIST_V3_HOST_DIR = os.path.join(HIST_V2_DIR, socket.gethostname())
HIST_V3_DIR = os.path.join(HIST_V3_HOST_DIR, 'shell')

TIMESTAMP_DELIM = ",'''"
TYPED_COMMAND_DELIM = "''','''"
EXECUTED_COMMAND_END = "'''"
ENTRY_END_MARK = EXECUTED_COMMAND_END + '\n'


class HistoryEntry:

    def __init__(self, invocation_time, typed_command, executed_command):
        self.invocation_time = invocation_time
        self.typed_command = typed_command
        self.executed_command = executed_command

    def __str__(self):
        return str(self.__dict__)


# History line example:
# 1469977033,'''pkg-config xinerama''','''pkg-config xinerama'''
#
# Note that there could be newlines inside the type command or executed command.
def _parse_history_v2_file_entry(hist_entry_string):
    end = hist_entry_string.index(TIMESTAMP_DELIM)
    timestamp = int(hist_entry_string[:end])
    invocation_time = datetime.datetime.fromtimestamp(timestamp)
    begin = end + len(TIMESTAMP_DELIM)
    end = hist_entry_string.index(TYPED_COMMAND_DELIM, begin)
    typed_command = hist_entry_string[begin:end]
    begin = end + len(TYPED_COMMAND_DELIM)
    executed_command = hist_entry_string[begin:-len(EXECUTED_COMMAND_END)]
    return HistoryEntry(invocation_time, typed_command, executed_command)


def _find_history_v2_entry_end(content, begin):
    while begin < len(content):
        try:
            end = content.index(ENTRY_END_MARK, begin)
        except ValueError:
            break
        next_timestamp_index = end + len(ENTRY_END_MARK)
        if next_timestamp_index == len(
                content) or content[next_timestamp_index].isdigit():
            return end
        begin = end + len(ENTRY_END_MARK)
    return len(content)


def _parse_history_v2_file_content(content, max_entries=None):
    entry_strings = []
    begin = 0
    while begin < len(content):
        end = _find_history_v2_entry_end(content, begin)
        # Use end+3 to add back the triple single quotations.
        entry_strings.append(content[begin:end + 3])
        begin = end + len(ENTRY_END_MARK)
    if max_entries:
        # pylint: disable=invalid-unary-operand-type
        entry_strings = entry_strings[-max_entries:]
    entries = []
    for entry_string in entry_strings:
        entries.append(_parse_history_v2_file_entry(entry_string))
    return entries


# Update 2017-10-02: I just measured the time it takes to call
# `history.parse_history_file()` using `timeit` in ipython and the
# result is 74ms on my laptop with ~10K history entries.
def parse_history_v2(max_entries=None):
    # Try with the hostname and fallback to the old path.
    # TODO: Remove this.
    for path in [
            os.path.join(HIST_V3_HOST_DIR, HIST_V2_FILENAME),
            os.path.join(HIST_V2_DIR, HIST_V2_FILENAME)
    ]:
        if os.path.exists(path):
            with open(path, encoding='utf-8', errors='ignore') as f:
                content = f.read()
            return _parse_history_v2_file_content(content, max_entries)
    return []


def get_hist_file_paths(hosts=None):
    available_hosts = os.listdir(HIST_V2_DIR)
    if not hosts:
        hosts = available_hosts
    invalid_hosts = set(hosts) - set(available_hosts)
    if invalid_hosts:
        raise ValueError(f'Invalid hosts: {invalid_hosts}, '
                         f'available hosts: {available_hosts}')
    hist_file_paths = []
    for host in hosts:
        hist_dir = os.path.join(HIST_V2_DIR, host, 'shell')
        if not os.path.exists(hist_dir):
            continue
        for filename in os.listdir(hist_dir):
            filepath = os.path.join(hist_dir, filename)
            if os.path.isfile(filepath) and filename.endswith('.csv'):
                hist_file_paths.append(filepath)
    return hist_file_paths


def parse_history_v3(max_entries=None, hosts=None):
    hist_file_paths = get_hist_file_paths(hosts)
    # History rows sorted from newest to oldest.
    rows = []
    # Process the files starting from the newest ones (last in lexicographic
    # sort order).
    for filepath in sorted(hist_file_paths, reverse=True):
        if max_entries and len(rows) == max_entries:
            break
        with open(filepath, encoding='utf-8', errors='ignore') as f:
            # Python chokes on null bytes although it's valid UTF-8, so we must
            # convert it.
            content = f.read().replace('\0', '')
        reader = csv.reader(io.StringIO(content))
        shard_rows = [l for l in reader if l]
        if max_entries and len(rows) + len(shard_rows) > max_entries:
            num_remaining = max_entries - len(rows)
            shard_rows = shard_rows[-num_remaining:]
        rows.extend(reversed(shard_rows))
    entries = []
    for row in reversed(rows):
        try:
            timestamp = int(row[0])
            invocation_time = datetime.datetime.fromtimestamp(timestamp)
            entries.append(HistoryEntry(invocation_time, row[1], row[2]))
        except ValueError as e:
            raise ValueError(f'Failed parsing row: "{row}"') from e
    return entries
