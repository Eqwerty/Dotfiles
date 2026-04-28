alias reload="source ~/.bashrc"
alias bashrc="vim ~/.bashrc"

alias ls='ls --color=auto --group-directories-first'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias f="ls -a | grep -i --color=auto"
cdm() { cd "$(ls -d */ | grep -i --color=auto "$1")"; }
catm() { cat "$(ls -p | grep -v / | grep -i --color=auto "$1")"; }
