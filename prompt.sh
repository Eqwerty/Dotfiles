# ------------------------------------------------------------
# Git prompt support
# ------------------------------------------------------------
if [ -f /usr/share/git/completion/git-prompt.sh ]; then
  . /usr/share/git/completion/git-prompt.sh
fi

# ------------------------------------------------------------
# Color palette (customize freely)
# ------------------------------------------------------------
# Standard ANSI colors:
# 0;30m black        1;30m bold black        0;90m light black
# 0;31m red          1;31m bold red          0;91m light red
# 0;32m green        1;32m bold green        0;92m light green
# 0;33m yellow       1;33m bold yellow       0;93m light yellow
# 0;34m blue         1;34m bold blue         0;94m light blue
# 0;35m magenta      1;35m bold magenta      0;95m light magenta
# 0;36m cyan         1;36m bold cyan         0;96m light cyan
# 0;37m white        1;37m bold white        0;97m light white

# User + host
CLR_USER="\e[0;32m"          # green

# Working directory
CLR_PATH="\e[38;5;136m"      # warm yellow

# Branch name
CLR_BRANCH="\e[0;36m"        # cyan

# Git status colors (per‑status)
CLR_STAGED="\e[0;32m"        # green (staged)
CLR_UNSTAGED="\e[0;31m"      # red (unstaged)
CLR_UNTRACKED="\e[0;31m"     # red (untracked)
CLR_STASH="\e[0;35m"         # magenta
CLR_AHEAD="\e[0;36m"         # cyan
CLR_BEHIND="\e[0;36m"        # cyan
CLR_STATE="\e[1;31m"         # bold red (rebase/merge/cherry-pick)

# Prompt symbol
CLR_PROMPT="\e[37m"          # white

# Reset
CLR_RESET="\e[0m"

# ------------------------------------------------------------
# Git status with added/modified/deleted/renamed (staged + unstaged)
# ------------------------------------------------------------
git_prompt_info() {
    git rev-parse --is-inside-work-tree &>/dev/null || return

    # -----------------------------
    # UNTRACKED
    # -----------------------------
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

    # -----------------------------
    # UNSTAGED CHANGES
    # -----------------------------
    local unstaged_added=$(git diff --name-status 2>/dev/null | grep -c '^A')
    local unstaged_modified=$(git diff --name-status 2>/dev/null | grep -c '^M')
    local unstaged_deleted=$(git diff --name-status 2>/dev/null | grep -c '^D')
    local unstaged_renamed=$(git diff --name-status 2>/dev/null | grep -c '^R')

    # -----------------------------
    # STAGED CHANGES
    # -----------------------------
    local staged_added=$(git diff --cached --name-status 2>/dev/null | grep -c '^A')
    local staged_modified=$(git diff --cached --name-status 2>/dev/null | grep -c '^M')
    local staged_deleted=$(git diff --cached --name-status 2>/dev/null | grep -c '^D')
    local staged_renamed=$(git diff --cached --name-status 2>/dev/null | grep -c '^R')

    # -----------------------------
    # STASH
    # -----------------------------
    local stash=$(git stash list 2>/dev/null | wc -l)

    # -----------------------------
    # AHEAD / BEHIND
    # -----------------------------
    local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    local ahead="" behind=""
    if [ -n "$upstream" ]; then
        ahead=$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null | awk '{print $1}')
        behind=$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null | awk '{print $2}')
    fi

    # -----------------------------
    # REBASE / MERGE / CHERRY-PICK
    # -----------------------------
    local state=""
    if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
        local cur=$(cat .git/rebase-merge/msgnum 2>/dev/null || cat .git/rebase-apply/next 2>/dev/null)
        local tot=$(cat .git/rebase-merge/end 2>/dev/null || cat .git/rebase-apply/last 2>/dev/null)
        state="${CLR_STATE}| REBASE ${cur}/${tot}${CLR_RESET}"
    elif [ -f .git/MERGE_HEAD ]; then
        state="${CLR_STATE}| MERGING${CLR_RESET}"
    elif [ -f .git/CHERRY_PICK_HEAD ]; then
        state="${CLR_STATE}| CHERRY-PICKING${CLR_RESET}"
    fi

    # -----------------------------
    # BUILD OUTPUT
    # -----------------------------
    local out=""

    # Ahead / behind
    [ "$ahead" != "0" ] && out+=" ${CLR_AHEAD}↑$ahead${CLR_RESET}"
    [ "$behind" != "0" ] && out+=" ${CLR_BEHIND}↓$behind${CLR_RESET}"

    # ---- STAGED (green) ----
    [ "$staged_added" -gt 0 ]    && out+=" ${CLR_STAGED}+${staged_added}${CLR_RESET}"
    [ "$staged_modified" -gt 0 ] && out+=" ${CLR_STAGED}~${staged_modified}${CLR_RESET}"
    [ "$staged_deleted" -gt 0 ]  && out+=" ${CLR_STAGED}-${staged_deleted}${CLR_RESET}"
    [ "$staged_renamed" -gt 0 ]  && out+=" ${CLR_STAGED}>${staged_renamed}${CLR_RESET}"

    # ---- UNSTAGED (red) ----
    [ "$unstaged_added" -gt 0 ]    && out+=" ${CLR_UNSTAGED}+${unstaged_added}${CLR_RESET}"
    [ "$unstaged_modified" -gt 0 ] && out+=" ${CLR_UNSTAGED}~${unstaged_modified}${CLR_RESET}"
    [ "$unstaged_deleted" -gt 0 ]  && out+=" ${CLR_UNSTAGED}-${unstaged_deleted}${CLR_RESET}"
    [ "$unstaged_renamed" -gt 0 ]  && out+=" ${CLR_UNSTAGED}>${unstaged_renamed}${CLR_RESET}"

    # ---- UNTRACKED (red) ----
    [ "$untracked" -gt 0 ] && out+=" ${CLR_UNTRACKED}?${untracked}${CLR_RESET}"

    # ---- STASH ----
    [ "$stash" -gt 0 ] && out+=" ${CLR_STASH}@$stash${CLR_RESET}"

    echo -e "${out} ${state}"
}

# ------------------------------------------------------------
# Prompt definition
# ------------------------------------------------------------
PS1='${debian_chroot:+($debian_chroot)}\
\['"$CLR_USER"'\]\u\['"$CLR_RESET"'\]\
\['"$CLR_PATH"'\] \w\['"$CLR_RESET"'\]\
\['"$CLR_BRANCH"'\]$(__git_ps1 " (%s)")\['"$CLR_RESET"'\]\
$(git_prompt_info)\
\n\['"$CLR_PROMPT"'\]> \['"$CLR_RESET"'\]'
