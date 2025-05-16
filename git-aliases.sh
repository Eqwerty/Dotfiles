# === Git Alias Index ===
# Clone:         gcl
# Add:           ga, gas, gass, gagr
# Commit:        gc, gca, gcae, gcne
# Branch:        gb, gbv, gba, gbr, gbd, gbdf, gbm, gco, gcot, gcob, gcobgr
# Merge:         gm, gma, gmc, gms
# Fetch:         gf, gfs
# Pull:          gpl, gpr
# Push:          gpo, gpof
# Rebase:        gr, gri, gra, grc
# Stash:         gsu, gsm, gsd, gsp, gsl, gsc
# Log:           glog, glogm, glh, gluh, glm
# Show:          gbl, gd, gds, ggr, gsh, gshno
# Reset:         grm, grhh, grh, grch
# Diff:          gd, gds, gdgr
# Status:        gs, gss
# Reflog:        gref
# File Checkout: gcofgr
# PR:            pr
# GitHub:        gh
# Utils:         gcurrent, gdefault, gcgl

alias gcl="git clone" # Clone a repository
alias ga="git add" # Add files to the staging area
alias gas="git add -A && git status" # Add all changes to the staging area and show the status
alias gass="git add -A && gss" # Add all changes to the staging area and show a short status
alias gbl="git blame --color-by-age --color-lines" # Show blame information with color-by-age and color-lines
alias gb="git branch" # List branches
alias gbv="git branch -vv" # List branches with verbose information
alias gba="git branch -a" # List all branches (local and remote)
alias gbr="git branch --remotes" # List remote branches
alias gbd="git branch -d" # Delete a local branch
alias gbdf="git branch -D" # Force delete a local branch
alias gbm="git branch -m" # Rename the current branch
alias gco="git checkout" # Switch branches
alias gcot="git checkout --track" # Switch to a remote branch and track it
alias gcob="git checkout -b" # Create and switch to a new branch
alias gcfd="git clean -fd" # Remove untracked files and directories
alias gc="git commit -m" # Commit with a message
alias gca="git commit --amend --no-edit" # Amend the last commit without changing the message
alias gcae="git commit --amend" # Amend the last commit and edit the message
alias gcne="git commit --no-edit" # Commit without editing the message
alias gd="git diff --color | diff-so-fancy" # Show changes between commits, branches, or the working directory
alias gds="git diff --color --staged | diff-so-fancy" # Show changes in the staging area
alias gf="git fetch" # Fetch changes from the remote
alias gfs="git fetch && git status" # Fetch changes and show the status
alias ggr="git grep --no-index -i -I --exclude-standard --heading --line-number" # Search for a string in the repository
alias glog="git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" # Show a graphical log with commit details
alias glogm="glog --author='$(git config --get user.email)'" # Show a graphical log with commits by the current user
alias glh="glog HEAD.." # Show commits in other branches not yet merged into HEAD
alias gluh="glog @{u}..HEAD" # Show commits not pushed to the upstream branch
alias gm="git merge --no-edit" # Merge branches without opening an editor
alias gma="git merge --abort" # Abort a merge
alias gmc="git merge --continue" # Continue a merge after resolving conflicts
alias gms="git merge --squash" # Squash commits during a merge
alias gpl="git pull" # Pull changes from the remote
alias gpr="git pull -r" # Pull changes and rebase
alias gpo="git push -u origin HEAD" # Push the current branch to the remote and set upstream
alias gpof="git push -u origin HEAD --force" # Force push the current branch to the remote
alias gr="git rebase" # Rebase the current branch
alias gri="git rebase -i" # Start an interactive rebase
alias grc="git rebase --continue" # Continue a rebase after resolving conflicts
alias gra="git rebase --abort" # Abort a rebase
alias gref="git reflog" # Show the reflog
alias grm="git reset --mixed" # Reset index but keep changes in the working directory (mixed mode)
alias grhh="git reset HEAD --hard" # Discards all uncommitted changes (hard reset).
alias gs="git status" # Show the status of the working directory
alias gss="git status -s" # Show a short status of the working directory
alias gsu="git stash -u" # Stash untracked changes
alias gsm="git stash -u -m" # Stash untracked changes with a message
alias gsd="git stash drop" # Drop a stash
alias gsp="git stash pop" # Apply the most recent stash
alias gsl="git stash list" # List all stashes
alias gsc="git stash clear" # Clear all stashes
alias gdefault="git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4" # Get the default branch name
alias gcurrent="git symbolic-ref --short HEAD" # Get the current branch name
alias gcgl="git config --global --list" # List the current global Git configuration

# Reset the current branch to n commits before HEAD
function grh() {
  if [ -z "$1" ]; then
    echo "Usage: grh <number-of-commits>"
    return 1
  fi
  git reset HEAD~$1
}

# Show details of a specific commit (or HEAD if none provided) using diff-so-fancy
function gsh() {
  local commit="${1:-HEAD}"
  git show "$commit" | diff-so-fancy
}

# Show names of files changed in a commit
function gshno() {
  local commit="${1:-HEAD}"
  git show "$commit" --name-only | diff-so-fancy
}

# Reset the current branch to the specified commit and apply --hard
function grch() {
  if [ -z "$1" ]; then
    echo "Usage: grch <commit-hash>"
    return 1
  fi
  git reset "$1" --hard
}
 
# Display a limited number of recent Git log entries (default: all)
function gl() {
    local count=${1:--1}
    glog -n $count
}
 
# Display a limited number of recent Git log entries (default: all) by the author logged in
function glm() {
    local count=${1:--1}
    glogm -n $count
}

# Show changes of a specific stash
function gssh() {
  if [ -z "$1" ]; then
    echo "Usage: gssh <stash-index>"
    return 1
  fi
  git stash show -p "stash@{$1}" | diff-so-fancy
}

# Check out a branch based on a partial name match.
function gcobgr() {
  if [ -z "$1" ]; then
    echo "Usage: gcogr <partial-branch-name>"
    return 1
  fi

  local match
  mapfile -t matches < <(git branch --list | grep -i "$1" | sed 's/^[* ] //')

  local count=${#matches[@]}

  if [ "$count" -eq 1 ]; then
    git checkout "${matches[0]}"
  elif [ "$count" -gt 1 ]; then
    echo "Multiple matches found:"
    for branch in "${matches[@]}"; do
      echo "  $branch"
    done
    return 2
  else
    echo "No branches found matching '$1'"
    return 3
  fi
}

# Check out a file based on a partial name match from modified files
function gcofgr() {
  __git_match_and_execute "gcofgr" "$1" "git checkout"
}

# Add a file based on a partial name match from modified files
function gagr() {
  __git_match_and_execute "gagr" "$1" "git add"
}

# Show the diff of a file based on a partial name match from modified files
function gdgr() {
  __git_match_and_execute "gdgr" "$1" "git diff"
}

# Create a pull request and open it in the default browser
function pr() {
  local github_url branch_name main_branch pr_url
  github_url=$(git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#https://#' -e 's@cloud:@cloud/@' -e 's@com:@com/@' -e 's%\.git$%%' | awk '/github/')
  branch_name=$(git symbolic-ref HEAD | cut -d"/" -f 3,4)
  main_branch=$(gdefault)
  pr_url="$github_url/compare/$main_branch...$branch_name"
  explorer.exe "$pr_url"
}
 
# Open the current branch or the main branch in the GitHub repository
function gh() {
  local github_url main_branch current_branch url
  github_url=$(git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#https://#' -e 's@cloud:@cloud/@' -e 's@com:@com/@' -e 's%\.git$%%' | awk '/github/')
  main_branch=$(gdefault)
  current_branch=$(gcurrent)
  url="$github_url"
  if [[ "$main_branch" != "$current_branch" ]]; then
    url="$github_url/tree/$current_branch"
  fi
  
  explorer.exe "$url"
}

# Execute a Git command on a file matched by partial name from the working directory
# Usage: __git_match_and_execute <description> <partial-file-name> <git-command>
# - If exactly one match is found, the command is run with that file.
# - If multiple matches are found, it lists them and exits with code 2.
# - If no match is found, it exits with code 3.
function __git_match_and_execute() {
  local description="$1"
  local partial_name="$2"
  local command="$3"

  if [ -z "$partial_name" ]; then
    echo "Usage: $description <partial-file-name>"
    return 1
  fi

  mapfile -t matches < <(git status --porcelain | awk '{print $2}' | grep -i "$partial_name")
  local count=${#matches[@]}

  if [ "$count" -eq 1 ]; then
    eval "$command \"${matches[0]}\""
  elif [ "$count" -gt 1 ]; then
    echo "Multiple matches found:"
    for file in "${matches[@]}"; do
      echo "  $file"
    done
    return 2
  else
    echo "No files found matching '$partial_name'"
    return 3
  fi
}
 
# Enable autocomplete for aliases
__git_complete ga _git_add
__git_complete gb _git_branch
__git_complete gbd _git_branch
__git_complete gbdf _git_branch
__git_complete gco _git_checkout
__git_complete gcot _git_checkout
__git_complete gd _git_diff
__git_complete gdno _git_diff
__git_complete gds _git_diff
__git_complete gdsno _git_diff
__git_complete ggr _git_grep
__git_complete glh _git_log
__git_complete gm _git_merge
__git_complete gms _git_merge
__git_complete gr _git_rebase
__git_complete gri _git_rebase
__git_complete gsh _git_show
