# Install git-completion and source it
GIT_COMPLETION=~/git-completion.bash
if [ ! -f "$GIT_COMPLETION" ]; then
  curl -o "$GIT_COMPLETION" https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
fi
if [ -f "$GIT_COMPLETION" ] && ! type __git_complete &>/dev/null; then
  . "$GIT_COMPLETION"
fi

# General aliases
eval "$(~/.local/bin/oh-my-posh init bash --config /mnt/c/Users/<user>/AppData/Local/Programs/oh-my-posh/themes/eqwerty.omp.json)"
