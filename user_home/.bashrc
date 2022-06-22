export BASH_SILENCE_DEPRECATION_WARNING=1

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi

if [ -x $HOME/bin/vars ]; then
    touch $HOME/.env_sh
    LANG=POSIX $HOME/bin/vars -bourne >| $HOME/.env_sh
    source $HOME/.env_sh
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes; export COLORTERM=yes;;
esac

# 'interactive' shell test
#if [[ $- == *i* ]]; then
if [ -t 0 ]; then
    #== Colors
    # Color    Value     RGB
    # black      0     0, 0, 0
    # red        1     max,0,0
    # green      2     0,max,0
    # yellow     3     max,max,0
    # blue       4     0,0,max
    # magenta    5     max,0,max
    # cyan       6     0,max,max
    # white      7     max,max,max
    rt=$(tput sgr0); r=$(tput setaf 1); g=$(tput setaf 2); b=$(tput setaf 4); y=$(tput setaf 3); m=$(tput setaf 5); c=$(tput setaf 6);
fi

# ANSI escape color codes
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

PROMPT_COMMAND='echo -ne "\033]0;${USER}@`uname -n` ${PWD}\007"'
if [ "$color_prompt" = yes ]; then
    # You’ll get the next string:
    # purple history number \!,
    # white :,
    # green ✓ if error code is 0, red ✗ if not,
    # light green username,
    # light red symbol @,
    # light cyan servername,
    # yellow :,
    # pink current dir,
    # '#' if root or '$' if user,
    # white >
    PS1='\[\033[00;35m\]\!\[\033[0m\]: $(if [[ $? == 0 ]]; then echo "\[\033[01;32m\]\342\234\223"; else echo "\[\033[01;31m\]\342\234\227"; fi) \[\033[01;32m\]\u\[\033[01;31m\]@\[\033[01;36m\]\h\[\033[01;33m\]:\[\033[01;35m\]\w\[\033[0m\]\$>\[\]'
else
    PS1='\! \u@\h:\w\$ '
fi
HISTCONTROL=ignoredups
HISTSIZE=1000

if [ -f $HOME/dev/GitHub/git/contrib/completion/git-completion.bash ]; then
    source $HOME/dev/GitHub/git/contrib/completion/git-completion.bash
fi

if [ -f $HOME/.maven-completion ]; then
    source $HOME/.maven-completion
fi

if [ -f $HOME/.cargo/env ]; then
    source $HOME/.cargo/env
fi

set -o noclobber
set -o vi

# Minor errors in the spelling of a directory component in a cd command are corrected.
# The errors checked for are transposed characters, a missing character, and one character too many.
# If a correction is found, the corrected file name is printed, and the command proceeds.
# This option is only used by interactive shells.
shopt -s cdspell

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# tab complete automatically cycle through options
# bind '"\t":menu-complete'
bind "TAB:menu-complete"; bind "set show-all-if-ambiguous on"; bind "set menu-complete-display-prefix on"
bind "set match-hidden-files off"

if [ -x $HOME/.cargo/bin/bat ]; then
    alias more=bat --style=plain
elif [ -x /usr/bin/less ]; then
    alias more=less
fi

alias sdb='source $HOME/.bashrc'
alias l='/bin/ls -F --color=auto'
alias la='/bin/ls -aF --color=auto'
alias ll='/bin/ls -lF --color=auto'
alias lsd='/bin/ls -lsd --color=auto'
alias lrt='/bin/ls -lrtc --color=auto'
alias lsr='/bin/ls -lSr --color=auto'
alias h=history
alias vi=vim
alias cl=clear
alias cp='/bin/cp -i'
alias mv='/bin/mv -i'
alias rm='/bin/rm -i'
alias waste='/bin/rm -f'
alias rot13='perl -pe tr/[a-m][n-z][A-M][N-Z]/[n-z][a-m][N-Z][A-M]/'
alias grep='/usr/bin/egrep'
alias cgrep='/usr/bin/egrep --color=always'
alias ic=imgcat
alias d='date "+%a %h %d    %D    Time: %r"'
alias timestamp='date +.%Y%m%d_%H%M%S'
alias ren=rename.pl
alias sc='screencapture -i -t jpg'
alias encrypt='gpg -c --personal-cipher-preferences=AES256'
alias preview='open -a Preview'
alias autobundle='perl -MCPAN -e autobundle'
alias mvnc='mvn -ff compile'
alias mvnd='mvn dependency:tree'
alias mvnp='mvn -Dmaven.test.skip=true package'
alias mvni='mvn -ff -Dmaven.test.skip=true clean compile install'
alias rsvd='Rscript -e "m<-matrix(1:9,nrow=3);print(m);s<-svd(m);print(s);s\$u%*%diag(s\$d)%*%t(s\$v)"'
alias shuffle='perl -MList::Util -e "print List::Util::shuffle <>"'
alias shufflei='perl -MList::Util -lne "print List::Util::shuffle split //"'
alias cargoi='cargo install --path .'
alias crun='cargo run --release -- '
alias ctest='cargo test --release -- '
alias redhat='mkdir -p /tmp/shared && docker run -p 2222:22 -it -v /tmp/shared:/tmp/shared redhat'
alias suse='mkdir -p /tmp/shared && docker run -p 2223:22 -it -v /tmp/shared:/tmp/shared opensuse'
alias ubuntu='mkdir -p /tmp/shared && docker run -p 2224:22 -it -v /tmp/shared:/tmp/shared ubuntu'
#alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
#alias macdown='/Applications/MacDown.app/Contents/MacOS/MacDown'
#alias awsls='$HOME/bin/aws-runas kt aws s3 ls --recursive p111-tds-explore-artifacts/ccg_lsa_space/'
#alias matd='maturin develop --release'
alias ve='source ~/venv/bin/activate'
alias da=deactivate
alias rust='cd ~/dev/Rust'
alias jl=jupyter-lab
alias rgr='rg -t rust'
alias vendor='metaflac --show-vendor-tag'
alias mlist='metaflac --list --block-type=VORBIS_COMMENT'
alias lip='for interface in `ifconfig | egrep "^\w+:" | cut -d: -f1`; do ip=`ipconfig getifaddr $interface` && echo "$interface: $ip"; done'
alias vip='perl -MNet::hostent -MSocket -le "chomp(\$h = \`hostname\`); print inet_ntoa(gethost(\$h)->addr)"'
# quit bash shell without saving history
alias hclear_exit='unset HISTFILE && exit'
alias nislab='ssh it-nislab-01.lasp.colorado.edu'
alias burner='ssh ops-burner.lasp.colorado.edu'
alias greengw='ssh green-gw1.ops.lasp.colorado.edu'
alias python=python3
alias pip=pip3
alias p1='openssl passwd -1' # Use the MD5 based BSD password algorithm 1
alias p5='openssl passwd -5' # Use the SHA256 based algorithms defined by Ulrich Drepper
alias p6='openssl passwd -6' # Use the SHA512 based algorithms defined by Ulrich Drepper
alias yc='conda config --set auto_activate_base true'
alias nc='conda config --set auto_activate_base false'
alias nocomment='egrep -v "^[[:space:]]*[#;]|^[[:space:]]*$" $1'
alias sha1='shasum -a 1'
alias sha2='shasum -a 256'

# awk '!a[$0]++'

pwvalidate() {
    if [ $# -ne 2 ]; then
        echo "Usage: password {SSHA}..."
    else
        echo "$@" | perl -MCrypt::SaltedHash -lae 'my ($pw, $ssha) = @F; my $csh = Crypt::SaltedHash->new(algorithm => "SHA-1"); $csh->add($pw); print Crypt::SaltedHash->validate($ssha, $pw) ? "valid" : "invalid"'
    fi
}

pwgenerate() {
    perl -MCrypt::SaltedHash -lne 'chomp; my $csh = Crypt::SaltedHash->new(algorithm => "SHA-1"); $csh->add($_); print $csh->generate'
}

prime() {
    if [ $# -ne 1 ]; then
        echo "Usage: prime nbits"
    else
        openssl prime -generate -bits $1
    fi
}

def() {
    if [ $# -ge 1 ]; then
        open dict://"$*"
    fi
}

psw() {
    if [ $# -gt 0 ]; then
        ps -ewwf | /usr/bin/egrep -i "$@"
    else
        ps -ewwf
    fi
}

jqc() {
    if [ $# -eq 1 ]; then
        jq -C . "$1" | less -R
    fi
}

macosver() {
    echo sw_vers
    echo -------
    sw_vers

    echo
    echo system_profiler SPSoftwareDataType SPHardwareDataType
    echo -----------------------------------------------------
    system_profiler SPSoftwareDataType SPHardwareDataType
}
