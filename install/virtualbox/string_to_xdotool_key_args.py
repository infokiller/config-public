#!/usr/bin/env python3

import sys

CHAR_TO_NAME = {
    ' ': 'space',
    '!': 'exclam',
    '"': 'quotedbl',
    '#': 'numbersign',
    '$': 'dollar',
    '%': 'percent',
    '&': 'ampersand',
    '(': 'parenleft',
    ')': 'parenright',
    '*': 'asterisk',
    '+': 'plus',
    ',': 'comma',
    '-': 'minus',
    '.': 'period',
    '/': 'slash',
    ':': 'colon',
    ';': 'semicolon',
    '<': 'less',
    '=': 'equal',
    '>': 'greater',
    '?': 'question',
    '@': 'at',
    '[': 'bracketleft',
    '^': 'asciicircum',
    '_': 'underscore',
    '{': 'braceleft',
    '|': 'bar',
    '}': 'braceright',
    '~': 'asciitilde',
    '\n': 'Return',
}


def main():
    text = ''.join(a for a in sys.argv[1:])
    output = []
    for c in text:
        output.append(CHAR_TO_NAME.get(c, c))
    print(' '.join(output))


if __name__ == "__main__":
    main()
