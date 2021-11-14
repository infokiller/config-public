# Public config repo

This repo contains config files (commonly called dotfiles) targeting Linux and
WSL. It is my humble attempt to optimize ergonomics, security, and productivity.
No doubt that I spent too much time micro-optimizing them, and I still have a
psychotic urge to keep improving them. Hopefully, I'll be able to recover one
day.

Feel free to steal anything that seems useful to you. That said, you shouldn't
blindly copy stuff because:

- I only test this repo on my machines so some things may be catastrophically
  broken for you
- Some config/scripts rely on git repos I haven't published publicly yet
- Some bits of my setup is highly optimized for my own taste and you will
  probably hate it

In addition, I provide absolutely no backward compatibility guarantees, and I
sometimes fully reset the git history and start from scratch (though that will
hopefully stop once this repo is more stable).

Specific configs that may be more interesting for you: vim, tmux, zsh, vscode,
ipython, ranger, i3, bash, and probably others I forgot.

## Coding guidelines

### General

- Don't split large files just for the sake of organization: it's usually better
  to do the organization within the file (using functions, etc). Good reasons
  for splitting files include:
  - There are use cases that require only using part of the file. For example,
    my shell configuration has separate files for defining functions and aliases
    (`functions.sh`) and for terminal settings (`settings.sh`), since I have a
    use case where only the former is needed (parsing shell aliases from
    IPython). In this case, using the same file for both would add cognitive
    burden when working on the IPython config and make the code uglier with
    conditionals.
  - Modularization and controlling internal dependencies. For example, if a
    large part of a file contains one public function that's used by other
    parts, and many private utility functions that are used only for
    implementing this public function, separating this public function and all
    its dependencies into a separate file can clarify the dependencies and
    reduce cognitive load.
  - Editors start crawling. As of 2020-05-06, I ran into issues with my vim
    config in files that have more than 1000 lines. It seems that vim plugin
    authors don't test or care about performance in these files much, and the
    situation may be similar in other editors.
- Lazy load and/or async load as much as possible to make startup time fast.
- Try to use native configuration facilities (conditionals, etc) for settings
  that differ between hosts. Resort to separate files only if necessary.
- Prefer Python over Bash for complex scripts (general rule of thumb: more than
  100 LOC).
- Don't use Python for tools that should launch fast (less than 100ms). Prefer
  Go in this case. For example,
  [i3-workspace-groups](https://github.com/infokiller/i3-workspace-groups) was
  written in Python, which causes some operations to have noticeable latency.
- Code copied from an external source should have a comment with a URL to the
  source.
- Directories that may contain python code should be named with underscores and
  not dashes, because python can't import from directories with underscores.
- Executable files should be named using dashes to separate words, not
  underscores, i.e. `my-tool` and not `my_tool`. They should also have no file
  extension.
- Importable files (Python or bash libraries, for example) should be named using
  underscores and have a file extension (`.sh` for shell scripts, `.py` for
  Python, etc.).

### Vimscript

I roughly follow
[Google's style guide](https://google.github.io/styleguide/vimscriptguide.xml)
with the following additions:

1. "Constants" should be named `LIKE_THIS` ("constants" is quoted because there
   aren't enforced constants in vim, this is only a convention).
1. There's no need to define a `addon-info.json` for plugins since it's rarely
   used by plugins.
1. There's no need to put commands, mappings, and autocommands in separate
   files, since I don't see any benefit in doing so.

### Shell: Bash and Zsh

Many scripts in this repo are written in bash and zsh. In order to make the code
easier to manage, I try to follow the
[Google Style Guide](https://google.github.io/styleguide/shellguide.html) along
with the following additions:

1. Bash scripts start with a `#!/usr/bin/env bash` shebang.
1. Functions that are private to the script and are not intended to be exported
   should have a leading underscore, for example `_my_func`. Functions that are
   exported from a script should never have a leading underscore, (i.e.
   `my_func`, not `_my_func`).
1. `printf '%s\n' "${var}"` is preferred over `echo "${var}"` because the latter
   can interpret escape sequences (such as `\b`). However, printing string
   literals with not special chars is fine and shorter (`echo 'message'`).
1. All scripts should pass shellcheck with no warnings or errors.
1. Single quotes are preferred over double quotes when substitution is not used.
1. Functions should not use the `function` keyword and should generally use
   underscores to separate words, unless they're interactive shell functions
   that are expected to be extracted to their own executable, in which case they
   can use dashes.
1. "Library scripts" (intended to be sourced from other scripts) should always
   use underscores in the filenames and end with a `.sh` filename extension,
   while "executable scripts" should always use dashes and without a filename
   extension.
1. Files are structured as following:

   1. Shebang line (if the script is executable)
   1. Script documentation, separated from the shebang with an empty line
   1. Setting error handling options
   1. Setting `${REPO_ROOT}` and other constants
   1. Sourcing other scripts
   1. Defining functions
   1. Defining a `main` function
   1. Calling `main`

   Example:

   ```sh
   #!/usr/bin/env bash
   #
   # This script does XYZ. Usage:
   #   my_script <arg> [opt_arg]

   # See https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
   set -o errexit -o errtrace -o nounset -o pipefail

   # shellcheck disable=SC2155
   readonly REPO_ROOT="$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]}" || echo "${HOME}")"
   readonly OTHER_CONST=3

   # shellcheck source=../../.my_scripts/lib/base.sh
   source -- "${REPO_ROOT}/.my_scripts/lib/base.sh"

   _private_func() {
     echo 'This is a private function'
   }

   main() {
     printf 'Called main with args: %s\n' "$*"
   }

   main "$@"
   ```

Note that old scripts may not conform to this style yet.
