# Configuration file for jupyter-server.

# pylint: disable-next=undefined-variable
c = get_config()  # noqa

c.ServerApp.contents_manager_class = 'jupytext.TextFileContentsManager'
c.ContentsManager.preferred_jupytext_formats_save = 'py:percent'
## Allow access to hidden files
#  Default: False
# c.ContentsManager.allow_hidden = False
c.ContentsManager.allow_hidden = True
