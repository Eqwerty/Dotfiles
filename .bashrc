# ====================== Git aliases ======================
# Clone a repository
alias gcl="git clone"

# Add files to the staging area
alias ga="git add"

# Add all changes to the staging area and show the status
alias gas="git add -A && git status"

# Add all changes, commit with a message
alias gac="gas && git commit -m"

# Show blame information with color-by-age and color-lines
alias gbl="git blame --color-by-age --color-lines"

# List branches
alias gb="git branch"

# List branches with verbose information
alias gbv="git branch -vv"

# List all branches (local and remote)
alias gba="git branch -a"

# List remote branches
alias gbr="git branch --remotes"

# Delete a local branch
alias gbd="git branch -d"

# Force delete a local branch
alias gbD="git branch -D"

# List branches merged into the current branch
alias gbm="git branch --merged"

# List branches not merged into the current branch
alias gbnm="git branch --no-merged"

# Rename the current branch
alias gbM="git branch -M"

# Switch branches
alias gco="git checkout"

# Switch to a remote branch and track it
alias gcot="git checkout --track"

# Create and switch to a new branch
alias gcob="git checkout -b"

# Remove untracked files and directories
alias gcfd="git clean -fd"

# Commit with a message
alias gc="git commit -m"

# Open the commit editor
alias gce="git commit"

# Amend the last commit without changing the message
alias gca="git commit --amend --no-edit"

# Amend the last commit and edit the message
alias gcae="git commit --amend"

# Commit without editing the message
alias gcne="git commit --no-edit"

# Show changes between commits, branches, or the working directory
alias gd="git diff"

# Show names of changed files only
alias gdno="git diff --name-only"

# Show changes in the staging area
alias gds="git diff --staged"

# Show names of staged files only
alias gdsno="git diff --staged --name-only"

# Fetch changes from the remote
alias gf="git fetch"

# Fetch changes and show the status
alias gfs="git fetch && git status"

# Search for a string in the repository
alias ggr="git grep --no-index -i -I --exclude-standard --heading --line-number"

# Show a graphical log with commit details
alias glog="git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Show a graphical log with commits by the current user
alias glogm="git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --author='$(git config --get user.email)'"

# Show commits not yet merged into HEAD
alias glh="glog HEAD.."

# Merge branches without opening an editor
alias gm="git merge --no-edit"

# Abort a merge
alias gma="git merge --abort"

# Continue a merge after resolving conflicts
alias gmc="git merge --continue"

# Squash commits during a merge
alias gms="git merge --squash"

# Pull changes from the remote
alias gpl="git pull"

# Pull changes and rebase
alias gpr="git pull -r"

# Push the current branch to the remote and set upstream
alias gpo="git push -u origin HEAD"

# Force push the current branch to the remote
alias gpof="git push -u origin HEAD --force"

# Rebase the current branch
alias gr="git rebase"

# Start an interactive rebase
alias gri="git rebase -i"

# Continue a rebase after resolving conflicts
alias grc="git rebase --continue"

# Abort a rebase
alias gra="git rebase --abort"

# Show the reflog
alias gref="git reflog"

# Reset index but keep changes in the working directory (mixed mode)
alias grm="git reset --mixed"

# Discards all uncommitted changes (hard reset).
alias grhh="git reset HEAD --hard"

# Show details of a commit
alias gsh="git show"

# Show names of files changed in a commit
alias gshno="git show --name-only"

# Show the status of the working directory
alias gs="git status"

# Show a short status of the working directory
alias gss="git status -s"

# Stash untracked changes
alias gsu="git stash -u"

# Stash untracked changes with a message
alias gsm="git stash -u -m"

# Drop a stash
alias gsd="git stash drop"

# Apply the most recent stash
alias gsp="git stash pop"

# List all stashes
alias gsl="git stash list"

# Clear all stashes
alias gsc="git stash clear"

# Get the default branch name
alias gdefault="git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4"

# Get the current branch name
alias gcurrent="git symbolic-ref --short HEAD"

# Get the configured Git username
alias guser="git config --get user.name"

# Get the configured Git email
alias gemail="git config --get user.email"

# List the current global Git configuration
alias gcgl="git config --global --list"
# =========================================================
 
# Reset the current branch to n commits before HEAD
function grh() {
  if [ -z "$1" ]; then
    echo "Usage: grh <number-of-commits>"
    return 1
  fi
  git reset HEAD~$1
}
 
# Reset the current branch to the specified commit and apply --hard
function grch() {
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
 
# Delete all local branches except the default one
function gdelbr() {
  local main_branch
  main_branch=$(gdefault)
  gco "$main_branch" && git branch | grep -v "$main_branch" | xargs git branch -D
}
 
# Check out a branch based on a partial name match.
function gcof() {
  if [ -z "$1" ]; then
    echo "Usage: gcof <partial-branch-name>"
    return 1
  fi
 
  local match
  mapfile -t matches < <(git branch --list "*$1*" | sed 's/^[* ] //' )
 
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

# Add a file based on a partial name match from modified files
function gaf() {
  if [ -z "$1" ]; then
    echo "Usage: gaf <partial-file-name>"
    return 1
  fi

  local match
  # Get all modified files
  mapfile -t matches < <(git status --porcelain | awk '{print $2}' | grep -i "$1")

  local count=${#matches[@]}

  if [ "$count" -eq 1 ]; then
    # Add the single matched file
    git add "${matches[0]}"
  elif [ "$count" -gt 1 ]; then
    # Show a message with multiple matches
    echo "Multiple matches found:"
    for file in "${matches[@]}"; do
      echo "  $file"
    done
    return 2
  else
    # No matches found
    echo "No files found matching '$1'"
    return 3
  fi
}

# Show the diff of a file based on a partial name match from modified files
function gdf() {
  if [ -z "$1" ]; then
    echo "Usage: gdf <partial-file-name>"
    return 1
  fi

  local match
  # Get all modified files
  mapfile -t matches < <(git status --porcelain | awk '{print $2}' | grep -i "$1")

  local count=${#matches[@]}

  if [ "$count" -eq 1 ]; then
    # Show the diff of the single matched file
    git diff "${matches[0]}"
  elif [ "$count" -gt 1 ]; then
    # Show a message with multiple matches
    echo "Multiple matches found:"
    for file in "${matches[@]}"; do
      echo "  $file"
    done
    return 2
  else
    # No matches found
    echo "No files found matching '$1'"
    return 3
  fi
}
 
# Create a pull request and open it in the default browser
function pr() {
  local github_url branch_name main_branch pr_url open_or_start uname
  github_url=$(git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#https://#' -e 's@cloud:@cloud/@' -e 's@com:@com/@' -e 's%\.git$%%' | awk '/github/')
  branch_name=$(git symbolic-ref HEAD | cut -d"/" -f 3,4)
  main_branch=$(gdefault)
  open_or_start='open'
  uname=$(uname)
  if [[ "$uname" == CYGWIN* || "$uname" == MINGW* || "$uname" == MSYS* ]]; then
    open_or_start='start'
  fi
  pr_url="$github_url/compare/$main_branch...$branch_name?expand=1"
  $open_or_start "$pr_url"
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
  start "$url"
}
 
# Find and display files or directories matching a string (case-insensitive)
function f() {
  # Store the result of ls | grep -i "string"
  local results=$(ls -a | grep -i -- "$1")
 
  # Check if results are empty
  if [ -z "$results" ]; then
    # If no result, notify the user
    echo -e "No files or directories found containing: $1"
  else
    # If results are found, show them with a "-" before each
    echo "$results" | sed 's/^/- /'
  fi
}
 
# Change directory to the first match for a given string (case-insensitive)
function cdf() {
  # Store the result of ls | grep -i "string" (directories only)
  local results=$(ls -d */ | grep -i -- "$1")
 
  # Check if results are empty
  if [ -z "$results" ]; then
    # If no result, notify the user
    echo -e "No directory found containing: $1"
  else
    # Count the number of results
    local count=$(echo "$results" | wc -l)
 
    if [ $count -eq 1 ]; then
      # If exactly one result, cd into that directory (remove trailing slash)
      cd "$(echo "$results" | sed 's/\/$//')"
    else
      # If multiple results, show them with a "-" before each
      echo -e "\nMultiple directories found containing: $1\n"
      echo "$results" | sed 's/^/- /'
    fi
  fi
}
 
# Display the contents of a file if exactly one match is found (case-insensitive)
function catf() {
  # Store the result of ls | grep -i "string"
  local results=$(ls -a | grep -i -- "$1")
  local count=$(echo "$results" | wc -l)
 
  # Check if results are empty
  if [ -z "$results" ]; then
    # If no result, notify the user
    echo -e "No files or directories found containing: $1"
  elif [ "$count" -eq 1 ]; then
    # If exactly one result is found, use cat to display the file's contents
    cat "$results"
  else
    # If multiple results are found, show them with a "-" before each
    echo -e "\nMultiple directories found containing: $1\n"
    echo "$results" | sed 's/^/- /'
  fi
}
 
# Open a solution file in Rider (defaults to the only solution if one match is found)
function rider() {
  # Search for .sln files in the current directory only
  local results=$(find . -maxdepth 1 -type f -iname "*.sln")
 
  # Check if no result was found
  if [ -z "$results" ]; then
    echo -e "No solution file found"
  else
    # Count the number of results
    local count=$(echo "$results" | wc -l)
 
    if [ "$count" -eq 1 ]; then
      # If exactly one result, open it in Rider
      rider64.exe "$results"
    else
      # If multiple results, show them with a "-" before each
      echo -e "\nMultiple solution files found\n"
      echo "$results" | sed 's/^/- /'
    fi
  fi
}
 
# General aliases
alias reload="source ~/.bashrc"
alias bashrc="subl ~/.bashrc"
alias cls="clear"
alias ls="ls --color=auto"
alias lsa="ls -a"
alias lsd="ls -d */"
alias ..="cd .."
alias rmf="rm -fr"
 
# Links
alias gitreference="start https://git-scm.com/docs"
 
# Enable autocomplete for aliases
__git_complete ga _git_add
__git_complete gb _git_branch
__git_complete gbd _git_branch
__git_complete gbD _git_branch
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
 
# Include additional files
if [ -f ~/routes.sh ]; then
    . ~/routes.sh
fi

eval "$(oh-my-posh init bash --config $POSH_THEMES_PATH/eqwerty.omp.json)"
