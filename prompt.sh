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
    local status
    status="$(git status --porcelain=2 --branch 2>/dev/null)" || return

    local untracked=0 conflicts=0 ahead=0 behind=0
    declare -A staged=([A]=0 [M]=0 [D]=0 [R]=0)
    declare -A unstaged=([A]=0 [M]=0 [D]=0 [R]=0)

    local line xy x y ab code symbol
    while IFS= read -r line; do
        case "$line" in
            "# branch.ab "*)
                ab="${line#\# branch.ab }"
                ahead="${ab%% *}"; ahead="${ahead#+}"
                behind="${ab##* }"; behind="${behind#-}"
                ;;
            "1 "*|"2 "*)
                xy="${line:2:2}"
                x="${xy:0:1}"
                y="${xy:1:1}"
                [[ -n "${staged[$x]+x}" ]] && ((staged[$x]++))
                [[ -n "${unstaged[$y]+x}" ]] && ((unstaged[$y]++))
                ;;
            "u "*) ((conflicts++)) ;;
            "? "*) ((untracked++)) ;;
        esac
    done <<< "$status"

    local stash
    stash="$(git rev-list --walk-reflogs --count refs/stash 2>/dev/null || echo 0)"

    local out=""
    [ "$ahead" -gt 0 ]  && out+=" ${CLR_AHEAD}↑$ahead${CLR_RESET}"
    [ "$behind" -gt 0 ] && out+=" ${CLR_BEHIND}↓$behind${CLR_RESET}"

    for code in A M D R; do
        case "$code" in
            A) symbol="+" ;;
            M) symbol="~" ;;
            D) symbol="-" ;;
            R) symbol="→" ;;
        esac
        [ "${staged[$code]}" -gt 0 ]   && out+=" ${CLR_STAGED}${symbol}${staged[$code]}${CLR_RESET}"
        [ "${unstaged[$code]}" -gt 0 ] && out+=" ${CLR_UNSTAGED}${symbol}${unstaged[$code]}${CLR_RESET}"
    done

    [ "$untracked" -gt 0 ] && out+=" ${CLR_UNTRACKED}?${untracked}${CLR_RESET}"
    [ "$stash" -gt 0 ]     && out+=" ${CLR_STASH}@$stash${CLR_RESET}"
    [ "$conflicts" -gt 0 ] && out+=" ${CLR_STATE}!${conflicts}${CLR_RESET}"

    printf "%b" "$out"
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