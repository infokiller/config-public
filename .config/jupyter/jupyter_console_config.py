# pylint: disable-next=undefined-variable
c = get_config()  # noqa: F821

## Whether to include output from clients other than this one sharing the same
#  kernel.
#  Required for jupyter-vim, see:
#  https://github.com/jupyter-vim/jupyter-vim#jupyter-configuration
c.ZMQTerminalInteractiveShell.include_other_output = True

## Text to display before the first prompt. Will be formatted with variables
#  {version} and {kernel_banner}.
c.ZMQTerminalInteractiveShell.banner = 'Jupyter console {version}'

## Shortcut style to use at the prompt. 'vi' or 'emacs'.
#c.ZMQTerminalInteractiveShell.editing_mode = 'emacs'

## The name of a Pygments style to use for syntax highlighting
c.ZMQTerminalInteractiveShell.highlighting_style = 'solarized-dark'

## How many history items to load into memory
c.ZMQTerminalInteractiveShell.history_load_length = 1000

## Use 24bit colors instead of 256 colors in prompt highlighting. If your
#  terminal supports true color, the following command should print 'TRUECOLOR'
#  in orange: printf "\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\n"
c.ZMQTerminalInteractiveShell.true_color = True
