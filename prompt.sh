# ------------------------------------------------------------
# Git prompt support (branch name extraction, __git_ps1, etc.)
# ------------------------------------------------------------
[ -f /usr/share/git/completion/git-prompt.sh ] && \
  . /usr/share/git/completion/git-prompt.sh
[ -f /usr/lib/git-core/git-sh-prompt ] && \
    . /usr/lib/git-core/git-sh-prompt

# ------------------------------------------------------------
# Color palette
# ------------------------------------------------------------
ESC=$'\e'
RESET="${ESC}[0m"

COLOR_USER="\e[0;32m"
COLOR_HOST="\e[1;35m"
COLOR_PATH="\e[38;5;172m"

COLOR_BRANCH="\e[1;36m"
COLOR_BRANCH_DETACHED="\e[1;36m"
COLOR_BRANCH_NO_UPSTREAM="\e[1;36m"

COLOR_STAGED="\e[0;32m"
COLOR_UNSTAGED="\e[0;31m"
COLOR_UNTRACKED="\e[0;31m"
COLOR_STASH="\e[1;35m"
COLOR_AHEAD="\e[1;36m"
COLOR_BEHIND="\e[1;36m"
COLOR_STATE="\e[1;31m"

COLOR_PROMPT="\e[0;37m"
COLOR_RESET="\e[0m"

# ------------------------------------------------------------
# Cache state for Git prompt
# ------------------------------------------------------------
__GIT_PROMPT_CACHE_KEY=""
__GIT_PROMPT_CACHE_VALUE=""

git_cache_key() {
    local repo
    repo="$(git rev-parse --git-dir 2>/dev/null)" || return 1

    printf "%s:%s:%s" \
        "$(stat -c %Y "$repo/HEAD" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/index" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/logs/refs/stash" 2>/dev/null || echo 0)"

    # Track in-progress operation files so prompt state refreshes immediately.
    printf ":%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" \
        "$(stat -c %Y "$repo/MERGE_HEAD" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/CHERRY_PICK_HEAD" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/REVERT_HEAD" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/BISECT_LOG" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/rebase-merge" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/rebase-apply" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/rebase-merge/msgnum" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/rebase-merge/end" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/rebase-apply/next" 2>/dev/null || echo 0)" \
        "$(stat -c %Y "$repo/rebase-apply/last" 2>/dev/null || echo 0)"
}

# ------------------------------------------------------------
# Count commits ahead of a base branch when no upstream exists.
# ------------------------------------------------------------
git_local_ahead_count() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 0; return; }

    local current_branch base_ref fork_point
    current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
    [[ -z "$current_branch" ]] && { echo 0; return; }

    base_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"

    if [[ -z "$base_ref" ]]; then
        for candidate in origin/main origin/master main master; do
            if git show-ref --verify --quiet "refs/remotes/$candidate" ||
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
      "1 "*|"2 "*)  
        local xy="${line:2:2}"
        case "${xy:0:1}" in A) ((sA++)) ;; M) ((sM++)) ;; D) ((sD++)) ;; R) ((sR++)) ;; esac
        case "${xy:1:1}" in A) ((uA++)) ;; M) ((uM++)) ;; D) ((uD++)) ;; R) ((uR++)) ;; esac
        ;;
      "u "*) ((conflicts++)) ;;
      "? "*) ((untracked++)) ;;
    esac
  done <<< "$status"

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
# Branch display with detached HEAD resolution (original behavior).
# ------------------------------------------------------------
git_branch_wrapper() {
    local raw
    raw="$(GIT_PS1_SHOWCOLORHINTS= __git_ps1 "%s")"

    # Detached HEAD
    if [[ -z "$(git symbolic-ref -q HEAD)" ]]; then
        # During an operation, __git_ps1 includes state like feature|REBASE 1/1
        if [[ "$raw" == *"|"* ]]; then
            printf "%b\n" "${COLOR_BRANCH_DETACHED}(${raw})${RESET}"
            return
        fi

        local commit short branch last_checkout_target
        commit=$(git rev-parse HEAD 2>/dev/null) || { echo ""; return; }
        short=$(git rev-parse --short HEAD 2>/dev/null) || { echo ""; return; }

        branch=""
        last_checkout_target="$(git reflog -1 --format='%gs' 2>/dev/null | sed -n 's/^checkout: moving from .* to \(.*\)$/\1/p')"

        if [[ -n "$last_checkout_target" ]]; then
            if git show-ref --verify --quiet "refs/heads/$last_checkout_target" ||
               git show-ref --verify --quiet "refs/remotes/$last_checkout_target" ||
               git show-ref --verify --quiet "$last_checkout_target"; then
                if git rev-parse --verify --quiet "${last_checkout_target}^{commit}" >/dev/null &&
                   [[ "$(git rev-parse "${last_checkout_target}^{commit}")" == "$commit" ]]; then
                    branch="$last_checkout_target"
                fi
            fi
        fi

        if [[ -z "$branch" ]]; then
            while IFS= read -r ref; do
                [[ "$ref" == */HEAD ]] && continue
                branch="$ref"
                break
            done < <(git for-each-ref --points-at "$commit" --format='%(refname:short)' refs/remotes 2>/dev/null)
        fi

        if [[ -z "$branch" ]]; then
            branch="$(git for-each-ref --points-at "$commit" --format='%(refname:short)' refs/heads 2>/dev/null | head -n 1)"
        fi

        local display
        if [[ -z "$branch" || "$branch" == "$short" ]]; then
            display="${short}..."
        else
            display="${branch} ${short}..."
        fi

        printf "%b\n" "${COLOR_BRANCH_DETACHED}(${display})${RESET}"
        return
    fi

    # Non-detached
    if [[ -z "$raw" ]]; then
        echo ""
        return
    fi

    # During an operation, show as-is without ≡/≢
    if [[ "$raw" == *"|"* ]]; then
        echo "(${raw})"
        return
    fi

    if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        echo "(${raw})"
    else
        printf "%b\n" "${COLOR_BRANCH_NO_UPSTREAM}*(${raw})${RESET}"
    fi
}

# ------------------------------------------------------------
# Compute Git segment (branch + status) — private helper
# ------------------------------------------------------------
_git_prompt_segment_compute() {
    local branch status
    branch="$(git_branch_wrapper)"
    status="$(git_prompt_info)"

    [[ -z "$branch" && -z "$status" ]] && return

    # branch_wrapper already handles colors for special cases;
    # we only wrap the whole block in COLOR_BRANCH for normal cases.
    printf "%b" "${COLOR_BRANCH}${branch}${COLOR_RESET}"
    printf "%b" "${status}"
}

# ------------------------------------------------------------
# Public Git segment with caching
# ------------------------------------------------------------
git_prompt_segment() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

    local key
    key="$(git_cache_key)" || return

    if [[ "$key" == "$__GIT_PROMPT_CACHE_KEY" ]]; then
        printf "%b" "$__GIT_PROMPT_CACHE_VALUE"
        return
    fi

    local value
    value="$(_git_prompt_segment_compute)"

    __GIT_PROMPT_CACHE_KEY="$key"
    __GIT_PROMPT_CACHE_VALUE="$value"

    printf "%b" "$value"
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
