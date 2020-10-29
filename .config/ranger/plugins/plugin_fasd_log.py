import ranger.api

# pylint: disable=invalid-name

old_hook_init = ranger.api.hook_init


def hook_init(fm):

    def fasd_add_executed_file():
        fm.execute_command('fasd --add "{}"'.format(fm.thisfile.path))

    def fasd_add_changed_directory():
        fm.execute_command('fasd --add "{}"'.format(fm.thisdir.path))

    fm.signal_bind('execute.before', fasd_add_executed_file)
    fm.signal_bind('cd', fasd_add_changed_directory)
    return old_hook_init(fm)


ranger.api.hook_init = hook_init
