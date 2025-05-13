alias reload="source ~/.bashrc"
alias bashrc="code ~/.bashrc"
alias cls="clear"
alias ls="ls --color=auto"
alias lsa="ls -a"
alias lsd="ls -d */"
alias ..="cd .."
alias rmf="rm -fr"

# Find and display files or directories matching a string
function f() {
  local query="$1"
  local results
  results=$(find . -maxdepth 1 -iname "*$query*" -printf "%f\n")

  if [[ -z "$results" ]]; then
    echo -e "No files or directories found containing: $query"
  else
    echo "$results" | sed 's/^/- /'
  fi
}

# Change directory to the first match for a given string
function cdgr() {
  local query="$1"
  local results
  IFS=$'\n' read -rd '' -a results < <(find . -maxdepth 1 -type d -iname "*$query*" -printf "%f\n")

  if [[ ${#results[@]} -eq 0 ]]; then
    echo -e "No directory found containing: $query"
  elif [[ ${#results[@]} -eq 1 ]]; then
    cd "${results[0]}" || echo "Failed to cd into ${results[0]}"
  else
    echo -e "\nMultiple directories found containing: $query\n"
    printf -- "- %s\n" "${results[@]}"
  fi
}

# Display the contents of a file if exactly one match is found
function catgr() {
  local query="$1"
  local results
  IFS=$'\n' read -rd '' -a results < <(find . -maxdepth 1 -type f -iname "*$query*" -printf "%f\n")

  if [[ ${#results[@]} -eq 0 ]]; then
    echo -e "No files found containing: $query"
  elif [[ ${#results[@]} -eq 1 ]]; then
    cat "${results[0]}"
  else
    echo -e "\nMultiple files found containing: $query\n"
    printf -- "- %s\n" "${results[@]}"
  fi
}

alias updategitaliases='curl -fsSL --ssl-no-revoke "https://raw.githubusercontent.com/Eqwerty/Dotfiles/refs/heads/main/git-aliases.sh" -o "$HOME/git-aliases.sh" && reload'

for alias_file in \
    ~/custom-aliases.sh \
    ~/git-aliases.sh \
    ~/route-aliases.sh \
    ~/link-aliases.sh; do
    if [[ -f $alias_file ]]; then
        source "$alias_file"
        alias_name=$(basename "$alias_file" .sh)
        alias "$alias_name"="code $alias_file"
    fi
done
