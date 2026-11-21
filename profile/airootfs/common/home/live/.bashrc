[[ $- != *i* ]] && return
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\[\e[38;5;39m\]\u@\h\[\e[0m\]:\w\$ '
