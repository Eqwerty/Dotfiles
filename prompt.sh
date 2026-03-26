# ------------------------------------------------------------
# Git prompt support
# ------------------------------------------------------------
if [ -f /usr/share/git/completion/git-prompt.sh ]; then
  . /usr/share/git/completion/git-prompt.sh
fi

# ------------------------------------------------------------
# Color palette
# ------------------------------------------------------------
CLR_USER="\e[0;32m"
CLR_HOST="\e[1;35m"
CLR_PATH="\e[38;5;172m"
CLR_BRANCH="\e[1;36m"

CLR_STAGED="\e[0;32m"
CLR_UNSTAGED="\e[0;31m"
CLR_UNTRACKED="\e[0;31m"
CLR_STASH="\e[38;5;244m"
CLR_AHEAD="\e[1;36m"
CLR_BEHIND="\e[1;36m"
CLR_STATE="\e[1;31m"

CLR_PROMPT="\e[0;37m"
CLR_RESET="\e[0m"

# ------------------------------------------------------------
# Git status summary
# ------------------------------------------------------------
git_prompt_info() {
    git rev-parse --is-inside-work-tree &>/dev/null || return

    local untracked=$(git ls-files --others --exclude-standard | wc -l)

    local unstaged_added=$(git diff --name-status | grep -c '^A')
    local unstaged_modified=$(git diff --name-status | grep -c '^M')
    local unstaged_deleted=$(git diff --name-status | grep -c '^D')
    local unstaged_renamed=$(git diff --name-status | grep -c '^R')

    local staged_added=$(git diff --cached --name-status | grep -c '^A')
    local staged_modified=$(git diff --cached --name-status | grep -c '^M')
    local staged_deleted=$(git diff --cached --name-status | grep -c '^D')
    local staged_renamed=$(git diff --cached --name-status | grep -c '^R')

    local stash=$(git stash list | wc -l)

    local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    local ahead="" behind=""
    if [ -n "$upstream" ]; then
        read ahead behind <<<"$(git rev-list --left-right --count HEAD..."$upstream")"
    fi

    local out=""

    [[ "$ahead" =~ ^[0-9]+$ ]]  && [ "$ahead" -gt 0 ]  && out+=" ${CLR_AHEAD}↑$ahead${CLR_RESET}"
    [[ "$behind" =~ ^[0-9]+$ ]] && [ "$behind" -gt 0 ] && out+=" ${CLR_BEHIND}↓$behind${CLR_RESET}"

    [ "$staged_added" -gt 0 ]    && out+=" ${CLR_STAGED}+${staged_added}${CLR_RESET}"
    [ "$staged_modified" -gt 0 ] && out+=" ${CLR_STAGED}~${staged_modified}${CLR_RESET}"
    [ "$staged_deleted" -gt 0 ]  && out+=" ${CLR_STAGED}-${staged_deleted}${CLR_RESET}"
    [ "$staged_renamed" -gt 0 ]  && out+=" ${CLR_STAGED}>${staged_renamed}${CLR_RESET}"

    [ "$unstaged_added" -gt 0 ]    && out+=" ${CLR_UNSTAGED}+${unstaged_added}${CLR_RESET}"
    [ "$unstaged_modified" -gt 0 ] && out+=" ${CLR_UNSTAGED}~${unstaged_modified}${CLR_RESET}"
    [ "$unstaged_deleted" -gt 0 ]  && out+=" ${CLR_UNSTAGED}-${unstaged_deleted}${CLR_RESET}"
    [ "$unstaged_renamed" -gt 0 ]  && out+=" ${CLR_UNSTAGED}>${unstaged_renamed}${CLR_RESET}"

    [ "$untracked" -gt 0 ] && out+=" ${CLR_UNTRACKED}?${untracked}${CLR_RESET}"
    [ "$stash" -gt 0 ]     && out+=" ${CLR_STASH}@$stash${CLR_RESET}"

    echo -e "$out"
}

# ------------------------------------------------------------
# Branch wrapper with detached HEAD detection
# ------------------------------------------------------------
git_branch_wrapper() {
    local ESC=$'\e'
    local ITALIC="${ESC}[3m"
    local RESET="${ESC}[0m"

    local raw="$(__git_ps1 "%s")"

    [[ -z "$raw" ]] && { echo ""; return; }

    # Detached HEAD
    if [[ -z "$(git symbolic-ref -q HEAD)" ]]; then
        local commit=$(git rev-parse HEAD)
        local short=$(git rev-parse --short HEAD)

        local branch=$(git for-each-ref --format="%(refname:short)" refs/heads refs/remotes \
            | while read ref; do
                [[ "$(git rev-parse "$ref")" == "$commit" ]] && echo "$ref"
            done | head -n 1)

        raw="${branch:+$branch }${short}..."

        echo -e "~${CLR_BRANCH}${ITALIC}(${raw})${RESET}"
        return
    fi

    # Normal branch
    echo "($raw)"
}

# ------------------------------------------------------------
# Prompt definition
# ------------------------------------------------------------
PS1='${debian_chroot:+($debian_chroot)}\
\['"$CLR_USER"'\]\u\['"$CLR_RESET"'\]\
\['"$CLR_HOST"'\] \h\['"$CLR_RESET"'\]\
\['"$CLR_PATH"'\] \w\['"$CLR_RESET"'\]\
\['"$CLR_BRANCH"'\] $(git_branch_wrapper)\['"$CLR_RESET"'\]\
$(git_prompt_info)\
\n\['"$CLR_PROMPT"'\]\$ \['"$CLR_RESET"'\]'