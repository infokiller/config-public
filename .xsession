#!/usr/bin/env sh

# This file is usually sourced from the display manager (at least this is the
# case with LightDM). However, the xsession script assumes it's executed in
# bash, and the display manager may use another shell. In addition, some things
# are better when the script is executed in isolation- for example, reported
# line numbers. Therefore, the actual xsession is executed from this script,
# where it will be executed in an isolated and guaranteed bash environment.
exec "${HOME}/.my_scripts/desktop_env/xsession" "$@"
