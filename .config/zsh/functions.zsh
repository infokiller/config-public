# Used by list-commands in ../bash/functions.sh.
_list_commands_zsh() {
  printf '%s\n' "${(k)builtins[@]}" "${(k)commands[@]}" "${(k)functions[@]}" \
    "${(k)aliases[@]}"
}

# run-help is aliased to man by default, which masks Zsh's built-in run-help
# command.
unalias run-help 2> /dev/null || true
autoload -Uz run-help
alias help=run-help

_get_alias_value() {
  printf '%s\n' "${(v)aliases[$1]}"
  # For bash:
  printf '%s\n' "${BASH_ALIASES[$1]}"
}
_add_alias_prefix() {
  local prefix="$1"
  local alias_name="$2"
  if alias "${alias_name}" > /dev/null; then
    local alias_value
    alias_value="$(_get_alias_value "${alias_name}")"
    # shellcheck disable=SC2139,SC2140
    alias "${alias_name}"="${prefix} ${alias_value}"
  fi
}
_nocorrect_alias() {
  alias_name="$1"
  if alias "${alias_name}" > /dev/null; then
    alias_value="$(_get_alias_value "${alias_name}")"
    # shellcheck disable=SC2139,SC2140
    alias "${alias_name}"="nocorrect ${alias_value}"
  fi
}

# Don't try to correct me on the following
for alias in c o v le; do
  _add_alias_prefix nocorrect "${alias}"
done

# NOTE: As of 2020-01-28, noglob is disabled because I find it annoying,
# especially when trying to use globs to specify multiple files in the file
# arguments.
# _add_alias_prefix noglob rg
# _add_alias_prefix noglob ag

define_global_alias=(alias)
if command_exists abbrev-alias; then
  define_global_alias=(abbrev-alias)
fi
define_global_alias+=(-g)
# Global aliases for commands I currently use at the end of pipelines.
"${define_global_alias[@]}" C='| xsel --input --clipboard'
"${define_global_alias[@]}" C='| xsel --input --clipboard'
"${define_global_alias[@]}" G='| rg'
"${define_global_alias[@]}" GL='| rgl'
"${define_global_alias[@]}" L="| less"
"${define_global_alias[@]}" RL="| richpager --"
"${define_global_alias[@]}" S='| sed -r '
"${define_global_alias[@]}" XS='| sensible-xargs sed -i -r '
"${define_global_alias[@]}" H="| head"
"${define_global_alias[@]}" T="| tail"
"${define_global_alias[@]}" TT="| prepend-time"
"${define_global_alias[@]}" Y="| yank"
"${define_global_alias[@]}" P="| py -x "
"${define_global_alias[@]}" N='>/dev/null'
"${define_global_alias[@]}" E='2>/dev/null'
"${define_global_alias[@]}" NE='&>/dev/null'
"${define_global_alias[@]}" PE='| pe | fzf --multi'
# shellcheck disable=SC2016
"${define_global_alias[@]}" PEE='PE | tr "\\n" " " | sensible-xargs "${EDITOR}" --'
# Select a field using awk.
"${define_global_alias[@]}" F1="| awk '{print \$1}'"
"${define_global_alias[@]}" F2="| awk '{print \$2}'"
"${define_global_alias[@]}" F3="| awk '{print \$3}'"
"${define_global_alias[@]}" F4="| awk '{print \$4}'"
"${define_global_alias[@]}" F5="| awk '{print \$5}'"
"${define_global_alias[@]}" F6="| awk '{print \$6}'"
"${define_global_alias[@]}" F7="| awk '{print \$7}'"
"${define_global_alias[@]}" F8="| awk '{print \$8}'"
"${define_global_alias[@]}" F9="| awk '{print \$9}'"

# _expand_lbuffer_aliases() {
#   local lbuffer_expanded
#   LBUFFER="$(_expand_command_aliases "$LBUFFER")" && LBUFFER="${lbuffer_expanded}"
# }
# zle -N _expand_lbuffer_aliases
#
# _expand_aliases_space() {
#     zle _expand_lbuffer_aliases
#     zle self-insert
# }
# zle -N _expand_aliases_space
#
# _expand_aliases_enter() {
#     zle _expand_lbuffer_aliases
#     zle accept-line
# }
# zle -N _expand_aliases_enter
#
# _bindkey_insert_keymaps ' ' _expand_aliases_space
# _bindkey_insert_keymaps '^M' _expand_aliases_enter
