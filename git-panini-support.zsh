compdef _git-pannini git-panini
function _git-panini() {
  local context curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    "1: :->subcmd" \
    "*::arg:->args"

  case $state in
    (subcmd)
      _values 'subcommand' status branch world path non-panini non-shared
      ;;
    (args)
      case $line[1] in
        (world)
          _arguments \
            '--verbose[more verbose]'
          ;;
        (path)
          local -U panini_names
          panini_names=(`git panini world`)
          _values 'panini repos' ${panini_names:s/panini://}
          ;;
        (status|branch|non-panini|non-shared|fetch|apply|noop|share)
          _message 'no more arguments'
          ;;
      esac
      ;;
  esac
}

compdef _cdp cdp
function cdp() {
  cd `git panini path panini:$1`
}

function _cdp() {
  local -U panini_names
  panini_names=(`git panini world`)
  _values 'panini repos' ${panini_names:s/panini://}
}
