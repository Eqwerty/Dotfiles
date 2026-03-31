# ------------------------------------------------------------
# Git prompt support (branch name extraction, __git_ps1, etc.)
# ------------------------------------------------------------
[ -f /usr/share/git/completion/git-prompt.sh ] && \
  . /usr/share/git/completion/git-prompt.sh

# ------------------------------------------------------------
# Color palette
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
# Count commits ahead of a base branch when no upstream exists.
# Attempts: origin/HEAD → common mainline names → upstream.
# ------------------------------------------------------------
git_local_ahead_count() {
    local current_branch base_ref fork_point

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 0; return; }

    current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
    [[ -z "$current_branch" ]] && { echo 0; return; }

    base_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"

    if [[ -z "$base_ref" ]]; then
        for candidate in origin/main origin/master main master; do
            if git show-ref --verify --quiet "refs/remotes/${candidate#origin/}" ||
               git show-ref --verify --quiet "refs/heads/${candidate#origin/}"; then
                base_ref="$candidate"
                break
            fi
        done
    fi

    [[ -z "$base_ref" ]] &&
      git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1 &&
      base_ref="@{u}"

    [[ -z "$base_ref" ]] && { echo 0; return; }

    fork_point="$(git merge-base --fork-point "$base_ref" HEAD 2>/dev/null || true)"
    [[ -z "$fork_point" ]] &&
      fork_point="$(git merge-base "$base_ref" HEAD 2>/dev/null || true)"

    if [[ -n "$fork_point" ]]; then
        git rev-list --count "${fork_point}..HEAD" 2>/dev/null || echo 0
    else
        git rev-list --count "${base_ref}..HEAD" 2>/dev/null || echo 0
    fi
}

# ------------------------------------------------------------
# Parse porcelain v2 output and summarize repo state.
# ------------------------------------------------------------
git_prompt_info() {
  local status line
  status="$(git status --porcelain=2 --branch 2>/dev/null)" || return

  local ahead=0 behind=0 has_upstream=0 untracked=0 conflicts=0 stash
  local sA=0 sM=0 sD=0 sR=0 uA=0 uM=0 uD=0 uR=0

  while IFS= read -r line; do
    case "$line" in
      "# branch.ab "*)  
        local ab="${line#\# branch.ab }"
        ahead="${ab%% *}"; ahead="${ahead#+}"
        behind="${ab##* }"; behind="${behind#-}"
        has_upstream=1
        ;;
      "1 "*|"2 "*)  # staged/unstaged changes
        local xy="${line:2:2}"
        case "${xy:0:1}" in A) ((sA++)) ;; M) ((sM++)) ;; D) ((sD++)) ;; R) ((sR++)) ;; esac
        case "${xy:1:1}" in A) ((uA++)) ;; M) ((uM++)) ;; D) ((uD++)) ;; R) ((uR++)) ;; esac
        ;;
      "u "*) ((conflicts++)) ;;
      "? "*) ((untracked++)) ;;
    esac
  done <<< "$status"

  # If no upstream, compute ahead count manually
  if [[ "$has_upstream" -eq 0 ]]; then
    ahead="$(git_local_ahead_count)"
    behind=0
  fi

  stash="$(git rev-list --walk-reflogs --count refs/stash 2>/dev/null || echo 0)"

  local out=""
  [ "$ahead"     -gt 0 ] && out+=" ${COLOR_AHEAD}↑${ahead}${COLOR_RESET}"
  [ "$behind"    -gt 0 ] && out+=" ${COLOR_BEHIND}↓${behind}${COLOR_RESET}"

  [ "$sA" -gt 0 ] && out+=" ${COLOR_STAGED}+${sA}${COLOR_RESET}"
  [ "$sM" -gt 0 ] && out+=" ${COLOR_STAGED}~${sM}${COLOR_RESET}"
  [ "$sD" -gt 0 ] && out+=" ${COLOR_STAGED}-${sD}${COLOR_RESET}"
  [ "$sR" -gt 0 ] && out+=" ${COLOR_STAGED}→${sR}${COLOR_RESET}"

  [ "$uA" -gt 0 ] && out+=" ${COLOR_UNSTAGED}+${uA}${COLOR_RESET}"
  [ "$uM" -gt 0 ] && out+=" ${COLOR_UNSTAGED}~${uM}${COLOR_RESET}"
  [ "$uD" -gt 0 ] && out+=" ${COLOR_UNSTAGED}-${uD}${COLOR_RESET}"
  [ "$uR" -gt 0 ] && out+=" ${COLOR_UNSTAGED}→${uR}${COLOR_RESET}"

  [ "$untracked" -gt 0 ] && out+=" ${COLOR_UNTRACKED}?${untracked}${COLOR_RESET}"
  [ "$stash"     -gt 0 ] && out+=" ${COLOR_STASH}@$stash${COLOR_RESET}"
  [ "$conflicts" -gt 0 ] && out+=" ${COLOR_STATE}!${conflicts}${COLOR_RESET}"

  printf "%b" "$out"
}

# ------------------------------------------------------------
# Branch display with detached HEAD resolution.
# Attempts to infer the original branch or remote ref.
# ------------------------------------------------------------
git_branch_wrapper() {
    local raw="$(__git_ps1 "%s")"
    [[ -z "$raw" ]] && { echo ""; return; }

    # Detached HEAD
    if [[ -z "$(git symbolic-ref -q HEAD)" ]]; then
        local commit short branch last_checkout_target
        commit=$(git rev-parse HEAD)
        short=$(git rev-parse --short HEAD)
        last_checkout_target="$(git reflog -1 --format='%gs' | sed -n 's/^checkout: moving from .* to \(.*\)$/\1/p')"

        # Prefer the checkout target if it resolves to this commit
        if [[ -n "$last_checkout_target" ]] &&
           git rev-parse --verify --quiet "${last_checkout_target}^{commit}" &&
           [[ "$(git rev-parse "${last_checkout_target}^{commit}")" == "$commit" ]]; then
            branch="$last_checkout_target"
        fi

        # Otherwise try remote branches
        if [[ -z "$branch" ]]; then
            branch="$(git for-each-ref --points-at "$commit" --format='%(refname:short)' refs/remotes \
                      | grep -v '/HEAD$' | head -n 1)"
        fi

        # Fallback to local branches
        [[ -z "$branch" ]] &&
          branch="$(git for-each-ref --points-at "$commit" --format='%(refname:short)' refs/heads | head -n 1)"

        printf "%b\n" "${COLOR_BRANCH_DETACHED}${ITALIC}(${branch:+$branch }${short}...)${RESET}"
        return
    fi

    # Normal branch
    if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        echo "(${raw})"
    else
        printf "%b\n" "${COLOR_BRANCH_NO_UPSTREAM}${ITALIC}(${raw})${RESET}"
    fi
}

# ------------------------------------------------------------
# Unified Git segment (branch + status)
# ------------------------------------------------------------
git_prompt_segment() {
    local branch status
    branch="$(git_branch_wrapper)"
    status="$(git_prompt_info)"

    [[ -z "$branch" && -z "$status" ]] && return

    printf "%b" "${COLOR_BRANCH}${branch}${COLOR_RESET}${status}"
}

# ------------------------------------------------------------
# Prompt definition
# ------------------------------------------------------------
PS1='${debian_chroot:+($debian_chroot)}\
\['"$COLOR_USER"'\]\u\['"$COLOR_RESET"'\]\
\['"$COLOR_HOST"'\] \h\['"$COLOR_RESET"'\]\
\['"$COLOR_PATH"'\] \w \['"$COLOR_RESET"'\]\
$(git_prompt_segment)\
\n\['"$COLOR_PROMPT"'\]\$ \['"$COLOR_RESET"'\]'