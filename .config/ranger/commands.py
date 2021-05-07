# -*- coding: utf-8 -*-
# This file is part of ranger, the console file manager.
# This configuration file is licensed under the same terms as ranger.
# ===================================================================
#
# NOTE: If you copied this file to ~/.config/ranger/commands_full.py,
# then it will NOT be loaded by ranger, and only serve as a reference.
#
# ===================================================================
# This file contains ranger's commands.
# It's all in python; lines beginning with # are comments.
#
# Note that additional commands are automatically generated from the methods
# of the class ranger.core.actions.Actions.
#
# You can customize commands in the file ~/.config/ranger/commands.py.
# It has the same syntax as this file.  In fact, you can just copy this
# file there with `ranger --copy-config=commands' and make your modifications.
# But make sure you update your configs when you update ranger.
#
# ===================================================================
# Every class defined here which is a subclass of `Command' will be used as a
# command in ranger.  Several methods are defined to interface with ranger:
#   execute():   called when the command is executed.
#   cancel():    called when closing the console.
#   tab(tabnum): called when <TAB> is pressed.
#   quick():     called after each keypress.
#
# tab() argument tabnum is 1 for <TAB> and -1 for <S-TAB> by default
#
# The return values for tab() can be either:
#   None: There is no tab completion
#   A string: Change the console to this string
#   A list/tuple/generator: cycle through every item in it
#
# The return value for quick() can be:
#   False: Nothing happens
#   True: Execute the command afterwards
#
# The return value for execute() and cancel() doesn't matter.
#
# ===================================================================
# Commands have certain attributes and methods that facilitate parsing of
# the arguments:
#
# self.line: The whole line that was written in the console.
# self.args: A list of all (space-separated) arguments to the command.
# self.quantifier: If this command was mapped to the key "X" and
#      the user pressed 6X, self.quantifier will be 6.
# self.arg(n): The n-th argument, or an empty string if it doesn't exist.
# self.rest(n): The n-th argument plus everything that followed.  For example,
#      if the command was "search foo bar a b c", rest(2) will be "bar a b c"
# self.start(n): Anything before the n-th argument.  For example, if the
#      command was "search foo bar a b c", start(2) will be "search foo"
#
# ===================================================================
# And this is a little reference for common ranger functions and objects:
#
# self.fm: A reference to the "fm" object which contains most information
#      about ranger.
# self.fm.notify(string): Print the given string on the screen.
# self.fm.notify(string, bad=True): Print the given string in RED.
# self.fm.reload_cwd(): Reload the current working directory.
# self.fm.thisdir: The current working directory. (A File object.)
# self.fm.thisfile: The current file. (A File object too.)
# self.fm.thistab.get_selection(): A list of all selected files.
# self.fm.execute_console(string): Execute the string as a ranger command.
# self.fm.open_console(string): Open the console with the given string
#      already typed in for you.
# self.fm.move(direction): Moves the cursor in the given direction, which
#      can be something like down=3, up=5, right=1, left=1, to=6, ...
#
# File objects (for example self.fm.thisfile) have these useful attributes and
# methods:
#
# tfile.path: The path to the file.
# tfile.basename: The base name only.
# tfile.load_content(): Force a loading of the directories content (which
#      obviously works with directories only)
# tfile.is_directory: True/False depending on whether it's a directory.
#
# For advanced commands it is unavoidable to dive a bit into the source code
# of ranger.
# ===================================================================

# pylint: disable=too-few-public-methods
# pylint: disable=invalid-name

from __future__ import absolute_import, division, print_function

import os
import re
import subprocess

# pylint: disable=import-error
from ranger.api.commands import Command


class recent_directories(Command):
    """
    :recent_directories

    Jump to recent directories using fasd
    """

    def execute(self):
        selector_executable = os.path.join(os.path.dirname(__file__),
                                           'fzf-select-dir')
        fasd_process = self.fm.execute_command(['fasd', '-dl'],
                                               stdout=subprocess.PIPE)
        selector_process = self.fm.execute_command(
            [selector_executable, '--tac'],
            stdin=fasd_process.stdout,
            stdout=subprocess.PIPE,
            universal_newlines=True)
        stdout, _ = selector_process.communicate()
        if selector_process.returncode == 0:
            directory = os.path.abspath(stdout.rstrip('\n'))
            assert os.path.isdir(directory)
            self.fm.execute_command(['fasd', '--add', directory])
            self.fm.cd(directory)


class recent_files(Command):
    """
    :recent_files

    Jump to recent files using fasd
    """

    def execute(self):
        selector_executable = os.path.join(os.path.dirname(__file__),
                                           'fzf-select-file')
        fasd_process = self.fm.execute_command(['fasd', '-fl'],
                                               stdout=subprocess.PIPE)
        selector_process = self.fm.execute_command(
            [selector_executable, '--tac'],
            stdin=fasd_process.stdout,
            stdout=subprocess.PIPE,
            universal_newlines=True)
        stdout, _ = selector_process.communicate()
        if selector_process.returncode == 0:
            file_path = os.path.abspath(stdout.rstrip('\n'))
            assert os.path.isdir(file_path)
            self.fm.execute_command(['fasd', '--add', file_path])
            self.fm.select_file(file_path)


class mkcd(Command):
    """
    :mkcd <dirname>

    Creates a directory with the name <dirname> and enters it.
    """

    def execute(self):

        dirname = os.path.join(self.fm.thisdir.path,
                               os.path.expanduser(self.rest(1)))
        if not os.path.lexists(dirname):
            os.makedirs(dirname)

            match = re.search('^/|^~[^/]*/', dirname)
            if match:
                self.fm.cd(match.group(0))
                dirname = dirname[match.end(0):]

            for match in re.finditer('[^/]+', dirname):
                s = match.group(0)
                if s == '..' or (s.startswith('.') and
                                 not self.fm.settings['show_hidden']):
                    self.fm.cd(s)
                else:
                    ## We force ranger to load content before calling `scout`.
                    self.fm.thisdir.load_content(schedule=False)
                    self.fm.execute_console('scout -ae ^{}$'.format(s))
        else:
            self.fm.notify("file/directory exists!", bad=True)


class fzf_select(Command):
    """
    :fzf_select

    Find a file using fzf.
    """

    def execute(self):
        selector_executable = os.path.join(os.path.dirname(__file__),
                                           'fzf-select-file')
        command = r"find -L . \( -fstype 'dev' -o -fstype 'proc' \) -prune \
                -o -print 2> /dev/null | \
                sed 1d | \
                cut -b3- | \
                {} +m".format(selector_executable)

        fzf = self.fm.execute_command(command,
                                      universal_newlines=True,
                                      stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class fzf_select_git(Command):
    """
    :fzf_select_git

    Find a file in a git repo using fzf.
    """

    def execute(self):
        selector_executable = os.path.join(os.path.dirname(__file__),
                                           'fzf-select-file')
        command = r"git-list-files | {} +m".format(selector_executable)

        fzf = self.fm.execute_command(command,
                                      universal_newlines=True,
                                      stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class fzf_select_by_line_count(Command):

    def execute(self):
        # directory = self.arg(0)
        # if not directory:
        directory = os.path.relpath(self.fm.thisdir.path)
        command = ['line-count-by-file-fzf', directory]
        fzf = self.fm.execute_command(command,
                                      universal_newlines=True,
                                      stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            line = stdout.split('\n')[0]
            # self.fm.notify(line)
            # line is formatted as "<count> <filename>"
            m = re.match(r'\s*\d+\s+(.*)$', line)
            if m:
                # NOTE: Only absolute paths work with select_file for some
                # reason.
                self.fm.select_file(os.path.abspath(m.groups()[0]))


def _split_args_to_batches(args, max_args_len):
    batches = []
    current_batch = []
    current_batch_len = 0
    for arg in args:
        arg_len = len(arg)
        if current_batch_len + arg_len > max_args_len:
            batches.append(current_batch)
            current_batch = []
            current_batch_len = 0
        current_batch.append(arg)
        current_batch_len += arg_len
    batches.append(current_batch)
    assert (sum(len(batch) for batch in batches)) == len(args)
    return batches


class trash_put(Command):
    """
    :trash_put

    Move files to XDG trash.
    """

    def execute(self):
        if self.rest(1):
            args = self.rest(1)
        elif self.fm.thistab.get_selection():
            args = [file.basename for file in self.fm.thistab.get_selection()]
        else:
            args = [self.fm.thisfile.basename]
        args_batches = _split_args_to_batches(args, 100000)
        self.fm.notify(os.getcwd())
        for batch in args_batches:
            self.fm.execute_command(['trash-put'] + batch)
