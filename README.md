# Delta Diff Tool

A simple guide to install and configure [delta](https://github.com/dandavison/delta?tab=readme-ov-file).

[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    dark = true
    side-by-side = true
[pager]
    diff = delta
    log = delta
    reflog = delta
    show = delta
[merge]
    conflictStyle = zdiff3

# Git Completion
https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

# Other useful packages
- batcat
- fzf