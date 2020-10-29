"""Utils."""
import collections
import io
import csv
import operator

import bashlex
import tabulate


def extract_sub_cmds_from_parts(cmd_parts):
    result = []
    for part in cmd_parts:
        if part.kind == 'command':
            subparts = part.parts[1:]
            cmd_with_args = [part.parts[0].word]
            for subpart in part.parts[1:]:
                if subpart.kind == 'word':
                    cmd_with_args.append(subpart.word)
            result.append(cmd_with_args)
        elif part.kind == 'commandsubstitution':
            subparts = [part.command]
        else:
            subparts = part.parts if hasattr(part, 'parts') else []
        result.extend(extract_sub_cmds_from_parts(subparts))
    return result


def split_to_sub_cmds(cmd):
    try:
        parts = bashlex.parse(cmd)
        return extract_sub_cmds_from_parts(parts)
    except Exception as e:
        print('Parse error for cmd:\n{}\n{}'.format(cmd, e))
        raise ValueError(e)


def compute_cmds_stats(cmds):
    cmds_counts = collections.Counter()
    args_counts = collections.Counter()
    num_complex_cmds = 0
    num_errors = 0
    for i, cmd in enumerate(cmds):
        try:
            subcmds = split_to_sub_cmds(cmd)
        except ValueError as error:
            print("Can't parse command in index {}:\n{}\nError: {}".format(
                i, cmd, error))
            num_errors += 1
            continue
        num_complex_cmds += len(subcmds) - 1
        for subcmd in subcmds:
            cmds_counts[subcmd[0]] += 1
            for word in subcmd[1:]:
                args_counts[word] += 1
    print('Number of commands: {}, complex commands: {}, errors: {}'.format(
        len(cmds), num_complex_cmds, num_errors))
    return list(cmds_counts.items()), list(args_counts.items())


def generate_csv_output(name_counts):
    stream = io.StringIO()
    csv_writer = csv.writer(stream)
    for name, count in name_counts:
        csv_writer.writerow([name, count])
    stream.seek(0)
    return stream.read()


def shorten_commands(cmds_counts):
    result = []
    for cmd in cmds_counts:
        name = cmd[0]
        if len(name) > 30:
            name = u'{}...{}'.format(name[:13], name[-14:])
        result.append((name, cmd[1]))
    return result


def compute_all_stats(cmds, max_printed_values=100, should_shorten=True):
    cmds_counts, args_counts = compute_cmds_stats(cmds)
    cmds_counts.sort(key=operator.itemgetter(1), reverse=True)
    args_counts.sort(key=operator.itemgetter(1), reverse=True)
    top_cmds_csv = generate_csv_output(cmds_counts[:500])
    with open('top_commands.csv', 'w') as f:
        f.write(top_cmds_csv)
    top_args_csv = generate_csv_output(args_counts[:500])
    with open('top_args.csv', 'w') as f:
        f.write(top_args_csv)
    if should_shorten:
        cmds_counts = shorten_commands(cmds_counts)
        args_counts = shorten_commands(args_counts)
    print('-' * 80)
    print('Top commands:')
    print(tabulate.tabulate(cmds_counts[:max_printed_values]))
    print('-' * 80)
    print('Top args:')
    print(tabulate.tabulate(args_counts[:max_printed_values]))
