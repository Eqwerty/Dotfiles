# ------------------------------------------------------------
# Git prompt support
# ------------------------------------------------------------
if [ -f /usr/share/git/completion/git-prompt.sh ]; then
  . /usr/share/git/completion/git-prompt.sh
fi

# ------------------------------------------------------------
# Variables and color palette
# ------------------------------------------------------------
ESC=$'\e'
RESET="${ESC}[0m"
ITALIC="${ESC}[3m"

COLOR_USER="\e[0;32m"
COLOR_HOST="\e[1;35m"
COLOR_PATH="\e[38;5;172m"
COLOR_BRANCH="\e[1;36m"
COLOR_BRANCH_DETACHED="\e[1;36m"
COLOR_BRANCH_NO_UPSTREAM="\e[1;36m"

COLOR_STAGED="\e[0;32m"
COLOR_UNSTAGED="\e[0;31m"
COLOR_UNTRACKED="\e[0;31m"
COLOR_STASH="\e[38;5;244m"
COLOR_AHEAD="\e[1;36m"
COLOR_BEHIND="\e[1;36m"
COLOR_STATE="\e[1;31m"

COLOR_PROMPT="\e[0;37m"
COLOR_RESET="\e[0m"

# ------------------------------------------------------------
# Git status summary
# ------------------------------------------------------------
git_prompt_info() {
    local status
    status="$(git status --porcelain=2 --branch 2>/dev/null)" || return

    local untracked=0 conflicts=0 ahead=0 behind=0
    declare -A staged=([A]=0 [M]=0 [D]=0 [R]=0)
    declare -A unstaged=([A]=0 [M]=0 [D]=0 [R]=0)

    local status_line xy_status index_status worktree_status ahead_behind status_code status_symbol
    while IFS= read -r status_line; do
        case "$status_line" in
            "# branch.ab "*)
                ahead_behind="${status_line#\# branch.ab }"
                ahead="${ahead_behind%% *}"; ahead="${ahead#+}"
                behind="${ahead_behind##* }"; behind="${behind#-}"
                ;;
            "1 "*|"2 "*)
                xy_status="${status_line:2:2}"
                index_status="${xy_status:0:1}"
                worktree_status="${xy_status:1:1}"
                [[ -n "${staged[$index_status]+x}" ]] && ((staged[$index_status]++))
                [[ -n "${unstaged[$worktree_status]+x}" ]] && ((unstaged[$worktree_status]++))
                ;;
            "u "*) ((conflicts++)) ;;
            "? "*) ((untracked++)) ;;
        esac
    done <<< "$status"

    local stash
    stash="$(git rev-list --walk-reflogs --count refs/stash 2>/dev/null || echo 0)"

    local out=""
    [ "$ahead" -gt 0 ]  && out+=" ${COLOR_AHEAD}↑$ahead${COLOR_RESET}"
    [ "$behind" -gt 0 ] && out+=" ${COLOR_BEHIND}↓$behind${COLOR_RESET}"

    for status_code in A M D R; do
        case "$status_code" in
            A) status_symbol="+" ;;
            M) status_symbol="~" ;;
            D) status_symbol="-" ;;
            R) status_symbol=">" ;;
        esac
        [ "${staged[$status_code]}" -gt 0 ]   && out+=" ${COLOR_STAGED}${status_symbol}${staged[$status_code]}${COLOR_RESET}"
        [ "${unstaged[$status_code]}" -gt 0 ] && out+=" ${COLOR_UNSTAGED}${status_symbol}${unstaged[$status_code]}${COLOR_RESET}"
    done

    [ "$untracked" -gt 0 ] && out+=" ${COLOR_UNTRACKED}?${untracked}${COLOR_RESET}"
    [ "$stash" -gt 0 ]     && out+=" ${COLOR_STASH}@$stash${COLOR_RESET}"
    [ "$conflicts" -gt 0 ] && out+=" ${COLOR_STATE}!${conflicts}${COLOR_RESET}"

    printf "%b" "$out"
}

# ------------------------------------------------------------
# Branch wrapper with detached HEAD detection
# ------------------------------------------------------------
git_branch_wrapper() {
    local raw="$(__git_ps1 "%s")"

    [[ -z "$raw" ]] && { echo ""; return; }

    # Detached HEAD
    if [[ -z "$(git symbolic-ref -q HEAD)" ]]; then
        local commit=$(git rev-parse HEAD)
        local short=$(git rev-parse --short HEAD)

        local branch=""
        local last_checkout_target=""
        last_checkout_target="$(git reflog -1 --format='%gs' 2>/dev/null | sed -n 's/^checkout: moving from .* to \(.*\)$/\1/p')"

        # Prefer the exact checkout target when it resolves to the detached commit.
        if [[ -n "$last_checkout_target" ]] && git rev-parse --verify --quiet "${last_checkout_target}^{commit}" >/dev/null; then
            if [[ "$(git rev-parse "${last_checkout_target}^{commit}")" == "$commit" ]]; then
                branch="$last_checkout_target"
            fi
        fi

        if [[ -z "$branch" ]]; then
            local ref

            # Prefer real remote branches (origin/master), but skip symbolic aliases like origin/HEAD.
            while IFS= read -r ref; do
                [[ "$ref" == */HEAD ]] && continue
                branch="$ref"
                break
            done < <(git for-each-ref --points-at "$commit" --format='%(refname:short)' refs/remotes)

            # Fallback to local branches if no remote branch points exactly at this commit.
            if [[ -z "$branch" ]]; then
                branch="$(git for-each-ref --points-at "$commit" --format='%(refname:short)' refs/heads | head -n 1)"
            fi
        fi

        raw="${branch:+$branch }${short}..."

        printf "%b\n" "${COLOR_BRANCH_DETACHED}${ITALIC}(${raw})${RESET}"
        return
    fi

    # Normal branch: keep tracked upstream behavior unchanged.
    if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        echo "(${raw})"
        return
    fi

    # No upstream configured for current branch.
    printf "%b\n" "${COLOR_BRANCH_NO_UPSTREAM}${ITALIC}(${raw})${RESET}"
}

# ------------------------------------------------------------
# Prompt definition
# ------------------------------------------------------------
PS1='${debian_chroot:+($debian_chroot)}\
\['"$COLOR_USER"'\]\u\['"$COLOR_RESET"'\]\
\['"$COLOR_HOST"'\] \h\['"$COLOR_RESET"'\]\
\['"$COLOR_PATH"'\] \w\['"$COLOR_RESET"'\]\
\['"$COLOR_BRANCH"'\] $(git_branch_wrapper)\['"$COLOR_RESET"'\]\
$(git_prompt_info)\
\n\['"$COLOR_PROMPT"'\]\$ \['"$COLOR_RESET"'\]'