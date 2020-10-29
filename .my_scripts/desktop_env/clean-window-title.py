#!/usr/bin/env python3
# pylint: disable=invalid-name

import datetime
import os
import re
import sys
import time


def get_punctuation_chars():
    puncuation_chars = {' ', '\t', '.', ',', ':', ';', '-'}
    for i in range(0x2000, 0x20ff):
        puncuation_chars.add(chr(i))
    return puncuation_chars


PUNCUATION_CHARS = get_punctuation_chars()
COMPESS_WHITESPACE_RE = re.compile(r'\s+')


def clean_title(title):
    if not title:
        return ''
    i = 0
    for i, char in enumerate(title):
        if char not in PUNCUATION_CHARS:
            break
    j = len(title) - 1
    while j >= i and title[j] in PUNCUATION_CHARS:
        j -= 1
    return re.sub(r'\s+', ' ', title[i:j+1])


def main():
    title = sys.stdin.read()
    sys.stdout.write(clean_title(title))
    sys.stdout.close()


if __name__ == '__main__':
    main()
