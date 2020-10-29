## Ideas

### i3-tmux seamless navigation

The idea is to define keybindings to navigate seamlessly between i3 windows and
tmux panes (similar to 
[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)).
Currently they are not ready for use. The reason is that while
they can detect if the current window is a tmux xterm (using the title), they
need to query tmux to find out whether the active pane is the
right-most/left-most/top-most/bottom-most so that in these cases i3 will escape
the tmux xterm window. If they will be used as is, once the focus is on an i3
tmux window it is not possible to navigate out of it.
