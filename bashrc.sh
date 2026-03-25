alias reload="source ~/.bashrc"
alias bashrc="code ~/.bashrc"

# Find and display files or directories matching a string
function f() {
  local query="$1"

  ls -a | grep -i "$query"
}

# Change directory to the first matching directory
function cdm() {
  _match d "$1" cd "directory"
}

# Display the contents of the first matching file
function catm() {
  _match f "$1" cat "file"
}

function _match() {
  local type="$1"
  local query="$2"
  local action="$3"
  local noun="$4"
  local results

  if [ -z "$query" ]; then
    echo "Usage: ${action}m <partial-${noun}-name>"
    return 1
  fi

  IFS=$'\n' read -rd '' -a results < <(find . -maxdepth 1 -type "$type" -iname "*$query*" -printf "%f\n")

  if [[ ${#results[@]} -eq 0 ]]; then
    echo -e "No ${noun}s found containing: $query"
  elif [[ ${#results[@]} -eq 1 ]]; then
    $action "${results[0]}" || echo "Failed to $action ${results[0]}"
  else
    echo -e "\nMultiple ${noun}s found containing: $query\n"
    printf -- "- %s\n" "${results[@]}"
  fi
}

alias updategitaliases='curl -fsSL --ssl-no-revoke "https://raw.githubusercontent.com/Eqwerty/Dotfiles/refs/heads/main/git_aliases.sh" -o "$HOME/.git_aliases.sh" && reload'

for alias_file in \
    ~/.prompt.sh \
    ~/.custom_aliases.sh \
    ~/.git_aliases.sh
do
    if [[ -f $alias_file ]]; then
        source "$alias_file"
        alias_name=$(basename "$alias_file" .sh)
        alias "$alias_name"="code $alias_file -n"
    fi
done
