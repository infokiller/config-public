The scripts in this directory are used to reset keyboard settings after certain
hardware events, namely:
* Resume from sleep
* New keyboard connection- happens sometimes when the cable on my desktop
  keyboard is not connected well enough.

The actual scripts that are configured to be run in the hardware events are the
`launch-*` scripts, which merely log the standard output and error of the "real"
scripts and changes the user using `su`.

> NOTE: As of 2020-05-05, the udev keyboard script moved to ~/.my_scripts/udev.
