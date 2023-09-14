# pylint: disable-next=undefined-variable
c = get_config()  # noqa: F821
#------------------------------------------------------------------------------
# JupyterQtConsoleApp(JupyterApp,JupyterConsoleApp) configuration
#------------------------------------------------------------------------------

## Whether to display a banner upon starting the QtConsole.
c.JupyterQtConsoleApp.display_banner = False

## Start the console window with the menu bar hidden.
#c.JupyterQtConsoleApp.hide_menubar = False

#------------------------------------------------------------------------------
# ConsoleWidget(NewBase) configuration
#------------------------------------------------------------------------------

## The maximum number of lines of text before truncation. Specifying a non-
#  positive number disables text truncation (not recommended).
c.ConsoleWidget.buffer_size = 10000

## The font family to use for the console. On OSX this defaults to Monaco, on
#  Windows the default is Consolas with fallback of Courier, and on other
#  platforms the default is Monospace.
c.ConsoleWidget.font_family = 'MyMono'

## The font size. If unconfigured, Qt will be entrusted with the size of the
#  font.
#c.ConsoleWidget.font_size = 0

## The type of completer to use. Valid values are:
#
#  'plain'   : Show the available completion as a text list
#              Below the editing area.
#  'droplist': Show the completion in a drop down list navigable
#              by the arrow keys, and from which you can select
#              completion by pressing Return.
#  'ncurses' : Show the completion as a text list which is navigable by
#              `tab` and arrow keys.
#c.ConsoleWidget.gui_completion = 'ncurses'

## Whether to include output from clients other than this one sharing the same
#  kernel.
#
#  Outputs are not displayed until enter is pressed.
c.ConsoleWidget.include_other_output = True

## Prefix to add to outputs coming from clients other than this one.
#
#  Only relevant if include_other_output is True.
#c.ConsoleWidget.other_output_prefix = '[remote] '

## The type of paging to use. Valid values are:
#
#  'inside'
#     The widget pages like a traditional terminal.
#  'hsplit'
#     When paging is requested, the widget is split horizontally. The top
#     pane contains the console, and the bottom pane contains the paged text.
#  'vsplit'
#     Similar to 'hsplit', except that a vertical splitter is used.
#  'custom'
#     No action is taken by the widget beyond emitting a
#     'custom_page_requested(str)' signal.
#  'none'
#     The text is written directly to the console.
#c.ConsoleWidget.paging = 'inside'

## The visibility of the scrollar. If False then the scrollbar will be invisible.
c.ConsoleWidget.scrollbar_visibility = False

#------------------------------------------------------------------------------
# FrontendWidget(HistoryConsoleWidget,BaseFrontendMixin) configuration
#------------------------------------------------------------------------------

## A Qt frontend for a generic Python kernel.

## Whether to clear the console when the kernel is restarted
#c.FrontendWidget.clear_on_kernel_restart = True

## Whether to ask for user confirmation when restarting kernel
#c.FrontendWidget.confirm_restart = True

## Whether to draw information calltips on open-parentheses.
#c.FrontendWidget.enable_calltips = True

## The pygments lexer class to use.
#c.FrontendWidget.lexer_class = traitlets.Undefined

#------------------------------------------------------------------------------
# JupyterWidget(IPythonWidget) configuration
#------------------------------------------------------------------------------

## A FrontendWidget for a Jupyter kernel.

## A command for invoking a GUI text editor. If the string contains a {filename}
#  format specifier, it will be used. Otherwise, the filename will be appended to
#  the end the command. To use a terminal text editor, the command should launch
#  a new terminal, e.g. ``"gnome-terminal -- vim"``.
c.JupyterWidget.editor = 'sensible-terminal -- vim "{filename}"'

## The editor command to use when a specific line number is requested. The string
#  should contain two format specifiers: {line} and {filename}. If this parameter
#  is not specified, the line number option to the %edit magic will be ignored.
#c.JupyterWidget.editor_line = ''

##
#c.JupyterWidget.in_prompt = 'In [<span class="in-prompt-number">%i</span>]: '

##
#c.JupyterWidget.input_sep = '\n'

##
#c.JupyterWidget.out_prompt = 'Out[<span class="out-prompt-number">%i</span>]: '

##
#c.JupyterWidget.output_sep = ''

##
#c.JupyterWidget.output_sep2 = ''

## If not empty, use this Pygments style for syntax highlighting. Otherwise, the
#  style sheet is queried for Pygments style information.
c.JupyterWidget.syntax_style = 'solarized-dark'
