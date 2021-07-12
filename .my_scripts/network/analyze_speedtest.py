#!/usr/bin/env python3

import argparse
import datetime
import os

import matplotlib.pyplot as plt
import pandas as pd


def main():
    parser = argparse.ArgumentParser(description='Analyze speedtest csv file')
    parser.add_argument('speedtest_file', help='Path to speedtest csv file')
    parser.add_argument('--min-datetime',
                        help='Minimum datetime of data to include')
    parser.add_argument('--last-days',
                        type=int,
                        default=30,
                        help='Number of days to include')
    args = parser.parse_args()
    min_datetime_str = datetime.datetime(1970, 1, 1)
    if args.min_datetime:
        min_datetime_str = '0'
    elif args.last_days:
        min_datetime_str = (
            datetime.datetime.now() -
            datetime.timedelta(days=args.last_days)).strftime('%Y-%m-%d')

    # pylint: disable=invalid-name
    df = pd.read_csv(args.speedtest_file)
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    df = df[df['Timestamp'] >= min_datetime_str]
    df = df.set_index('Timestamp')
    df['Download'] = df['Download'] / (1000**2)
    df['Upload'] = df['Upload'] / (1000**2)
    _, ax = plt.subplots()
    df[['Download', 'Upload']].ewm(alpha=0.1).mean().plot(ax=ax)
    plt.show()


if __name__ == '__main__':
    main()
