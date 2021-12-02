#!/usr/bin/env python3
# pylint: disable=invalid-name

import csv
import io
import math
import os

import history

MAX_ENTRIES_PER_SHARD = 10000


def write_csv_shard(entries, path):
    stream = io.StringIO()
    csv_writer = csv.writer(stream,  # nosemgrep: python.lang.security.unquoted-csv-writer.unquoted-csv-writer
                            lineterminator='\n',
                            quoting=csv.QUOTE_MINIMAL)
    for entry in entries:
        csv_writer.writerow([
            int(entry.invocation_time.timestamp()),
            entry.typed_command,
            entry.executed_command,
        ])
    stream.seek(0)
    print(f'Writing CSV shard: {path}')
    with open(path, 'w') as f:
        f.write(stream.read())


def shard_index_to_filename(shard_index):
    return f'{shard_index:03d}.csv'


def shard_history_entries(entries):
    num_shards = int(math.ceil(len(entries) / MAX_ENTRIES_PER_SHARD))
    shards = []
    for i in range(num_shards):
        begin = i * MAX_ENTRIES_PER_SHARD
        end = min((i + 1) * MAX_ENTRIES_PER_SHARD, len(entries))
        shards.append(entries[begin:end])
    return shards


def main():
    print('Parsing history')
    entries = history.parse_history_v2()
    print(f'Parsed {len(entries)} entries')
    if not os.path.exists(history.HIST_V3_DIR):
        os.makedirs(history.HIST_V3_DIR)
    shards = shard_history_entries(entries)
    for _, shard in enumerate(shards):
        # filename = f'{i:03d}.csv'
        filename = shard[0].invocation_time.strftime('%Y-%m-%d.csv')
        path = os.path.join(history.HIST_V3_DIR, filename)
        write_csv_shard(shard, path)


if __name__ == '__main__':
    main()
