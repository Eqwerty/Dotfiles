if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[38;5;28m\]\u@\h\[\033[00m\] \[\033[38;5;136m\]\w\[\033[00m\]$(__git_ps1 " \[\033[38;5;32m\](%s\[\033[38;5;32m\])")\n\[\033[37m\]$ \[\033[00m\]'
else
    PS1='${debian_chroot:+($debian_chroot)}\[\033[38;5;28m\]\u@\h\[\033[00m\] \[\033[38;5;136m\]\w\[\033[00m\]$(__git_ps1 " \[\033[38;5;32m\](%s\[\033[38;5;32m\])")\n\[\033[37m\]$ \[\033[00m\]'
fi
unset color_prompt force_color_prompt
 
# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

eval "$(~/.local/bin/oh-my-posh init bash --config /mnt/c/Users/<user>/AppData/Local/Programs/oh-my-posh/themes/eqwerty.omp.json)"
