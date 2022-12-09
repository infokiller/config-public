# pylint: disable=undefined-variable

_CM_CLASS = 'jupytext.TextFileContentsManager'
if hasattr(c.ServerApp, 'contents_manager_class'):
    c.ServerApp.contents_manager_class = _CM_CLASS
else:
    c.NotebookApp.contents_manager_class = _CM_CLASS
del _CM_CLASS
# Use the percent format when saving as py
c.ContentsManager.preferred_jupytext_formats_save = 'py:percent'
