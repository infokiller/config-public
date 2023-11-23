# Based on ipython-autotime [1] with modifications:
# - Only print execution time if it's more than a threshold
# - Print a fancy clock and use dim, italic text for the execution time
# - Don't rely on the private _format_time function
# - Use more verbose formatting and print current time
#
# [1] https://github.com/cpcloud/ipython-autotime/blob/master/autotime/__init__.py

import math
import sys
import time

from IPython import get_ipython


# Copied from _format_time in IPython/core/magics/execution.py
def _format_timespan(timespan, precision=3):
    if timespan >= 60.0:
        # we have more than a minute, format that in a human readable form
        # Idea from http://snipplr.com/view/5713/
        parts = [('d', 60 * 60 * 24), ('h', 60 * 60), ('min', 60), ('s', 1)]
        result = []
        leftover = timespan
        for suffix, length in parts:
            value = int(leftover / length)
            if value > 0:
                leftover = leftover % length
                result.append(f'{value}{suffix}')
            if leftover < 1:
                break
        return ' '.join(result)

    # Unfortunately the unicode 'micro' symbol can cause problems in
    # certain terminals.
    # See bug: https://bugs.launchpad.net/ipython/+bug/348466
    # Try to prevent crashes by being more secure than it needs to
    # E.g. eclipse is able to print a µ, but has no sys.stdout.encoding set.
    units = ['s', 'ms', 'us', 'ns']  # the save value
    if hasattr(sys.stdout, 'encoding') and sys.stdout.encoding:
        try:
            '\xb5'.encode(sys.stdout.encoding)
            units = ['s', 'ms', '\xb5s', 'ns']
        # pylint: disable=bare-except
        except:
            pass
    scaling = [1, 1e3, 1e6, 1e9]

    if timespan > 0.0:
        order = min(-int(math.floor(math.log10(timespan)) // 3), 3)
    else:
        order = 3
    return '%.*g%s' % (precision, timespan * scaling[order], units[order])


def _dim(text):
    if sys.stdout.isatty():
        return f'\033[2m{text}\033[22m'
    return text


def _italicize(text):
    if sys.stdout.isatty():
        return f'\033[3m{text}\033[0m'
    return text


class LineWatcher:
    __slots__ = ['start_time']

    def __init__(self):
        self.start_time = None

    def start(self, *_):
        self.start_time = time.monotonic()

    def stop(self, *_):
        delta = time.monotonic() - self.start_time
        if delta < 1:
            return
        # U+23F1 is a unicode stopwatch but doesn't render in Kitty.
        # Alternatives from Nerd Font: 
        print(_italicize(_dim(f' {_format_timespan(delta)}')))


def register_hook():
    timer = LineWatcher()
    ipy = get_ipython()
    ipy.events.register('pre_run_cell', timer.start)
    ipy.events.register('post_run_cell', timer.stop)


register_hook()
