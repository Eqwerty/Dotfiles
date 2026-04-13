# ============================ Clone ============================
alias gcl="git clone" # Clone a repository

# ============================ Add ============================
alias ga="git add" # Add files to the staging area
alias gaa="git add -A" # Add all changes to the staging area
alias gas="git add -A && git status -s" # Add all changes to the staging area and show a short status
alias gap="git add --patch" # Interactively stage changes in the working directory

# Add a file based on a partial name match from modified files
function gam() {
  __git_match_and_execute "gam" "$1" "git add"
}

# ============================ Commit ============================
alias gc="git commit -m" # Commit with a message
alias gca="git commit --amend --no-edit" # Amend the last commit without changing the message
alias gcam="git commit --amend -m" # Amend the last commit and edit the message

# ============================ Branch ============================
alias gb="git branch" # List branches
alias gbv="git branch -vv" # List branches with verbose information
alias gba="git branch -a" # List all branches (local and remote)
alias gbr="git branch --remotes" # List remote branches
alias gbd="git branch -d" # Delete a local branch
alias gbD="git branch -D" # Force delete a local branch
alias gbm="git branch -m" # Rename the current branch
alias gco="git checkout" # Switch branches
alias gcot="git checkout --track" # Switch to a remote branch and track it
alias gcob="git checkout -b" # Create and switch to a new branch

# Check out a branch based on a partial name match.
function gcobm() {
  if [ -z "$1" ]; then
    echo "Usage: gcobm <partial-branch-name>"
    return 1
  fi

  mapfile -t matches < <(git branch --list | grep -i "$1" | sed 's/^[* ] //')

  case ${#matches[@]} in
    1) git checkout "${matches[0]}" ;;
    0) echo "No branches found matching '$1'" ; return 3 ;;
    *) echo "Multiple matches found:"; printf "  %s\n" "${matches[@]}"; return 2 ;;
  esac
}

# ============================ Merge ============================
alias gm="git merge --no-edit" # Merge branches without opening an editor
alias gma="git merge --abort" # Abort a merge
alias gmc="git merge --continue" # Continue a merge after resolving conflicts
alias gms="git merge --squash" # Squash commits during a merge

# ============================ Fetch ============================
alias gf="git fetch" # Fetch changes from the remote
alias gfa="git fetch --all" # Fetch changes from all remotes
alias gfs="git fetch && git status" # Fetch changes and show the status

# ============================ Pull ============================
alias gpl="git pull" # Pull changes from the remote
alias gplr="git pull -r" # Pull changes and rebase

# ============================ Push ============================
alias gpo="git push -u origin HEAD" # Push the current branch to the remote and set upstream
alias gpof="git push -u origin HEAD --force-with-lease" # Force push the current branch to the remote

# ============================ Rebase ============================
alias gr="git rebase" # Rebase the current branch
alias gri="git rebase -i" # Start an interactive rebase
alias gra="git rebase --abort" # Abort a rebase
alias grc="git rebase --continue" # Continue a rebase after resolving conflicts

# ============================ Stash ============================
alias gsu="git stash -u" # Stash untracked changes
alias gsum="git stash -u -m" # Stash untracked changes with a message
alias gsd="git stash drop" # Drop a stash
alias gsp="git stash pop" # Apply the most recent stash
alias gsl="git stash list" # List all stashes
alias gsc="git stash clear" # Clear all stashes
alias gsa="git stash apply" # Apply a stash

# Show changes of a specific stash
function gssh() {
  if [ -z "$1" ]; then
    echo "Usage: gssh <stash-index>"
    return 1
  fi
  git stash show -w -p stash@{$1}
}

# ============================ Log ============================
alias glog="git log --graph --pretty=format:'%C(bold cyan)%h%Creset%C(auto)%d%Creset %C(white)%s %Cgreen(%cr) %C(bold cyan)<%an>%Creset' --abbrev-commit" # Show a graphical log with commit details
alias glogm="glog --author='$(git config --get user.email)'" # Show a graphical log with commits by the current user
alias glh="glog HEAD.." # Show commits in other branches not yet merged into HEAD
alias gluh="glog @{u}..HEAD" # Show commits not pushed to the upstream branch

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

# Copy the short hash of the Nth most recent commit to the clipboard
function gcc() {
  local index commit_hash short_hash commit_message

  if [ -z "$1" ]; then
    echo "Usage: gcc <commit-position>"
    echo "Example: gcc 4"
    return 1
  fi

  if ! [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: commit-position must be a positive integer"
    return 1
  fi

  index="$1"
  commit_hash=$(git rev-list --max-count="$index" HEAD 2>/dev/null | tail -n 1)

  if [ -z "$commit_hash" ]; then
    echo "Error: could not find commit at position $index"
    return 1
  fi

  short_hash=$(git rev-parse --short "$commit_hash")
  commit_message=$(git show -s --format=%s "$commit_hash")

  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$short_hash" | iconv -f UTF-8 -t UTF-16LE | clip.exe
  elif command -v clip >/dev/null 2>&1; then
    printf '%s' "$short_hash" | clip
  else
    echo "Error: no clipboard command found (expected clip.exe or clip)"
    return 1
  fi

  echo "Copied commit #$index: $short_hash - $commit_message"
}

# ============================ Show ============================
alias gbl="git blame --color-by-age --color-lines" # Show blame information with color-by-age and color-lines
alias ggr="git grep --no-index -i -I --exclude-standard --heading --line-number" # Search for a string in the repository
alias gsh="git show -w" # Show details of a commit
alias gshno="git show --name-only" # Show names of files changed in a commit

# ============================ Reset ============================
alias grm="git reset --mixed" # Reset index but keep changes in the working directory (mixed mode)
alias grhh="git reset HEAD --hard" # Discards all uncommitted changes (hard reset).

# Reset the current branch to n commits before HEAD
function grh() {
  if [ -z "$1" ]; then
    echo "Usage: grh <number-of-commits>"
    return 1
  fi
  git reset HEAD~$1 --soft
}

# Reset the current branch to the specified commit and apply --hard
function grch() {
  if [ -z "$1" ]; then
    echo "Usage: grch <commit-hash>"
    return 1
  fi
  git reset "$1" --hard
}

# ============================ Diff ============================
alias gd="git diff -w" # Show changes between commits, branches, or the working directory
alias gds="git diff -w --staged" # Show changes in the staging area
alias gdfu="git diff --name-only --diff-filter=U" # Show files with unmerged changes or conflicts

# Show the diff of a file based on a partial name match from modified files
function gdm() {
  __git_match_and_execute "gdm" "$1" "git diff"
}

# Show the diff of a staged file based on a partial name match from modified files
function gdsm() {
  __git_match_and_execute "gdsm" "$1" "git diff --staged"
}

# ============================ Status ============================
alias gs="git status" # Show the status of the working directory
alias gss="git status -s" # Show a short status of the working directory

# ============================ Reflog ============================
alias gref="git reflog" # Show the reflog

# ============================ File Checkout ============================
# Check out a file based on a partial name match from modified files
function gcofm() {
  __git_match_and_execute "gcofm" "$1" "git checkout"
}

# ============================ Cherry-Pick ============================
alias gcp="git cherry-pick" # Apply the changes introduced by an existing commit
alias gcpa="git cherry-pick --abort" # Cancel the cherry-picking operation and return to the pre-sequence state.
alias gcpc="git cherry-pick --continue" # Continue the cherry-picking operation in progress.

# ============================ Links ============================
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

# ============================ Utils ============================
# Get the default branch name with fallbacks when origin/HEAD is not configured
function gdefault() {
  local default_branch

  default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | cut -d'/' -f2)

  if [ -z "$default_branch" ]; then
    default_branch=$(git remote show origin 2>/dev/null | awk -F': ' '/HEAD branch/ {print $2; exit}')
  fi

  if [ -z "$default_branch" ]; then
    default_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  fi

  printf '%s\n' "$default_branch"
}

alias gcurrent="git symbolic-ref --short HEAD" # Get the current branch name
alias gcgl="git config --global --list" # List the current global Git configuration
alias gcge="git config --global --edit" # Opens the global Git configuration file
alias gcfd="git clean -fd" # Remove untracked files and directories

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

  case ${#matches[@]} in
    1) eval "$command \"${matches[0]}\"" ;;
    0) echo "No files found matching '$partial_name'" ; return 3 ;;
    *) echo "Multiple matches found:"; printf "  %s\n" "${matches[@]}"; return 2 ;;
  esac
}
 
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
