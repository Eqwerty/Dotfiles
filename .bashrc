# Git aliases
alias gcl="git clone"
alias ga="git add"
alias gas="git add -A && git status"
alias gac="gas && git commit -m"
alias gbl="git blame --color-by-age --color-lines"
alias gb="git branch"
alias gbv="git branch -vv"
alias gba="git branch -a"
alias gbr="git branch --remotes"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gbm="git branch --merged"
alias gbnm="git branch --no-merged"
alias gbM="git branch -M"
alias gco="git checkout"
alias gcot="git checkout --track"
alias gcob="git checkout -b"
alias gcfd="git clean -fd"
alias gc="git commit -m"
alias gce="git commit"
alias gca="git commit --amend --no-edit"
alias gcae="git commit --amend"
alias gcne="git commit --no-edit"
alias gd="git diff"
alias gdno="git diff --name-only"
alias gds="git diff --staged"
alias gdsno="git diff --staged --name-only"
alias gf="git fetch"
alias gfs="git fetch && git status"
alias ggr="git grep --no-index -i -I --exclude-standard --heading --line-number"
alias glog="git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glh="glog head.."
alias gm="git merge --no-edit"
alias gma="git merge --abort"
alias gmc="git merge --continue"
alias gms="git merge --squash"
alias gpl="git pull"
alias gpr="git pull -r"
alias gpo="git push -u origin HEAD"
alias gpof="git push -u origin HEAD --force"
alias gr="git rebase"
alias gri="git rebase -i"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias gref="git reflog"
alias grm="git reset --mixed"
alias grhh="git reset HEAD --hard"
alias gsh="git show"
alias gs="git status"
alias gss="git status -s"
alias gsu="git stash -u"
alias gsm="git stash -u -m"
alias gsd="git stash drop"
alias gsp="git stash pop"
alias gsl="git stash list"
alias gsc="git stash clear"
alias gnewbr="gcopm && git checkout -b"
alias gdefault="git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4"
alias gcurrent="git symbolic-ref --short HEAD"
alias guser="git config --get user.name"
alias gemail="git config --get user.email"

# Reset the current branch to n commits before HEAD (default is 1)
function grh() {
    local count=${1:-1}
    git reset HEAD~$count
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

# Delete all local branches except the default one
function gdelbr() {
  local main_branch
  main_branch=$(gdefault)
  gco "$main_branch" && git branch | grep -v "$main_branch" | xargs git branch -D
}

# Checkout the default branch and pull the latest changes from the remote
function gcopm() {
  local main_branch
  main_branch=$(gdefault)
  gco "$main_branch" && gpr
}

# Stash changes, create a new branch, and pop the stash
function gstnewbr() {
    git stash -u && gnewbr "$1" && gsp
}

# Add changes, commit with a message, pull and rebase, then push
function gcpp() {
    gas && gc "$1" && gpr && gpo
}

# Add changes, commit with a message, and push to the remote
function gcp() {
    gas && gc "$1" && gpo
}

# Add changes, commit with a message, push to the remote, and create a pull request
function gcpr() {
    gcp "$1" && pr
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

# Docker aliases
alias dps="docker ps"
alias dpsa="docker ps -a"
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcreset="dcd && dcu"

# K8s aliases
alias k='kubectl'

# Dotnet aliases
alias dn="dotnet"
alias dnc="dotnet clean"
alias dnre="dotnet restore"
alias dnb="dotnet build"
alias dnbnre="dotnet build --no-restore"
alias dnt="dotnet test"
alias dntnre="dotnet test --no-restore"
alias dntnb="dotnet test --no-build"
alias dnr="dotnet run"

# General aliases
alias reload="source ~/.bashrc"
alias bashrc="subl ~/.bashrc"
alias cls="clear"
alias ls="ls --color=auto"
alias lsa="ls -a"
alias lsd="ls -d */"
alias ..="cd .."

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
