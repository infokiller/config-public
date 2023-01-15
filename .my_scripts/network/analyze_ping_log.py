#!/usr/bin/env python3

import argparse
import datetime
import decimal
import os
import re
import sys

import numpy as np
import scipy.signal
from matplotlib import pyplot as plt

# import pandas as pd

PING_TIME_REGEX = re.compile(r'^\[(\d+\.\d+)].*time=(\d+\.?\d*) ms$')
PING_STATS_REGEX = re.compile(r'^(\d)+ packets transmitted, (\d)+ received,')


def _parse_ping_latencies(log_content, min_datetime):
    datetimes = []
    latencies = []
    for line in log_content.split('\n'):
        match = PING_TIME_REGEX.match(line)
        if not match:
            continue
        timestamp = float(match.groups()[0])
        latency_ms = float(match.groups()[1])
        ping_dt = datetime.datetime.fromtimestamp(timestamp)
        if ping_dt >= min_datetime:
            datetimes.append(ping_dt)
            latencies.append(latency_ms)
    return (datetimes, latencies)


def _parse_packet_loss(log_content, min_datetime):
    datetimes = []
    sent = []
    received = []
    last_datetime = None
    for line in log_content.split('\n'):
        match = PING_TIME_REGEX.match(line)
        if match:
            timestamp = float(match.groups()[0])
            last_datetime = datetime.datetime.fromtimestamp(timestamp)
            continue
        if not last_datetime or last_datetime < min_datetime:
            continue
        match = PING_STATS_REGEX.match(line)
        if not match:
            continue
        datetimes.append(last_datetime)
        sent.append(int(match.groups()[0]))
        received.append(int(match.groups()[1]))
    return (datetimes, sent, received)


def compute_percentile(values, percentile):
    assert 0 <= percentile <= 1
    return sorted(values)[int(percentile * len(values))]


# pylint: disable=too-many-locals
def main():
    parser = argparse.ArgumentParser(description='Analyze ping times log.')
    parser.add_argument('--ping-log-files',
                        help='Comma delimited list of ping log files',
                        required=True)
    parser.add_argument('--min-datetime',
                        help='Minimum datetime of data to include',
                        required=False)
    parser.add_argument('--smoothing-kernel-size',
                        type=int,
                        help='Dimension of smoothing kernel',
                        default=10)
    args = parser.parse_args()
    min_datetime = datetime.datetime(1970, 1, 1)
    if args.min_datetime:
        min_datetime = datetime.datetime.strptime(args.min_datetime,
                                                  '%Y-%m-%d %H:%M:%S')
    for path in args.ping_log_files.split(','):
        path = os.path.expanduser(path)
        print('Parsing file: {}'.format(path))
        if not os.path.exists(path):
            sys.exit('File not found: {}'.format(path))
        with open(path, encoding='utf-8') as f:
            log_content = f.read()
        label = os.path.basename(path)
        loss_dt, sent, received = _parse_packet_loss(log_content, min_datetime)
        lost = [s - r for s, r in zip(sent, received)]
        print('Packet loss: {:.1f}% ({}/{})'.format(100 * sum(lost) / sum(sent),
                                                    sum(lost), sum(sent)))
        datetimes, latencies = _parse_ping_latencies(log_content, min_datetime)
        sorted_latencies = sorted(latencies)
        percentile_latencies = []
        for percentile in [50, 90, 99]:
            index = int(percentile / 100 * len(latencies))
            percentile_latencies.append((percentile, sorted_latencies[index]))
        print('Latency percentiles: {}'.format(', '.join(
            '{}%: {:6.2f}'.format(l[0], l[1]) for l in percentile_latencies)))
        smoothing_filter = scipy.signal.windows.hann(args.smoothing_kernel_size)
        smoothing_filter /= sum(smoothing_filter)
        latencies = np.convolve(latencies, smoothing_filter, mode='same')
        plt.plot(datetimes, latencies, label=label)
        for i, l in enumerate(lost):
            if l > 0:
                frac = l / sent[i]
                plt.axvline(x=loss_dt[i],
                            color='red',
                            alpha=0.4,
                            linewidth=5*frac)
    plt.legend()
    plt.show()


if __name__ == '__main__':
    main()
