# Don't disable anything by default- the default vim profile is over restrictive
# with access to configuration files that I often edit, sudo for writing to root
# files, etc.
# I played a bit with firejail settings, but couldn't find settings that
# seemed to provide reasonable security without damaging usability.
# TODO: find better firejail settings for vim or ditch it.
# NOTE: As of 2020-02-13, I collected some of the required vim settings in
# firenvim.inc.
quiet
