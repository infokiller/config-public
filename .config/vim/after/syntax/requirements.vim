syntax clear requirementsComment
syntax case match
syntax keyword requirementsTodo contained TODO NOTE EXP FIXME XXX TBD
highlight link requirementsTodo Todo
syntax region requirementsComment start="[ \t]*#" end="$" contains=@Spell,requirementsTodo
