#!/bin/bash
#
# dwf -- initial
# Fri Jun 17 22:36:41 MDT 2022

# current supported distributions by this script
OPENSUSE_LEAP='opensuse/leap'
REDHAT_UBI9='redhat/ubi9'
UBUNTU_KINETIC='ubuntu:kinetic'
DEBIAN_BULLSEYE='debian:bullseye'

DISTRIBUTIONS="[$OPENSUSE_LEAP] [$REDHAT_UBI9] [$UBUNTU_KINETIC] [$DEBIAN_BULLSEYE]"

############################################################################
# Note:
#   I'm installing a set of workable packages I desire for each distribution
#   maintaining custom utility portability across architectures is fluid
############################################################################

# specific to each distribution: sudo, locale, system ssh host keys,
# package specific names (e.g. openssh vs openssh-clients + openssh-server)
shared_pkg_names='gcc git jq less make man net-tools perl rsync sudo vim'
 
DEBIAN_INSTALL="apt-get update && \
    apt-get -y install $shared_pkg_names curl iputils-ping iproute2 openjdk-17-jdk locales man-db openssh-client openssh-server man-db perl python3 python3-pip r-base tree expect slapd ldap-utils gnutls-bin ssl-cert && \
    sed -i 's,%sudo.*,%sudo ALL=(ALL:ALL) NOPASSWD: ALL,' /etc/sudoers && \
    sed -i 's/^#X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config && \
    sed -i 's/^# en_US/en_US/' /etc/locale.gen && dpkg-reconfigure --frontend=noninteractive locales && \
    mkdir /run/sshd && ssh-keygen -A && \
    if [ -x /usr/local/sbin/unminimize ]; then yes | /usr/local/sbin/unminimize; fi
    "
OPENSUSE_INSTALL="zypper refresh && \
    zypper -n install $shared_pkg_names curl expect java-17-openjdk-devel iputils iproute man-pages openssh perl python39 R-core-packages tree xauth && \
    groupadd wheel && \
    ln -s /usr/bin/python3.9 /usr/bin/python3 && \
    sed -i 's/^#X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config && \
    sed -i 's,# %wheel,%wheel,' /etc/sudoers && \
    ssh-keygen -A && \
    if [ -s /usr/share/vim/vim82/scripts.vim ]; then sed -i 's,^call dist#script#DetectFiletype(),\" call dist#script#DetectFiletype(),' /usr/share/vim/vim82/scripts.vim; fi
    "
REDHAT_INSTALL="yum -y install $shared_pkg_names diffutils glibc-langpack-en iputils iproute man-db openssh-clients openssh-server procps python39 xauth && \
    sed -i 's,# %wheel,%wheel,' /etc/sudoers && \
    sed -i 's/^#X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config && \
    sed -i 's/^#X11Forwarding.*/X11UseLocalhost yes/' /etc/ssh/sshd_config && \
    ssh-keygen -A
    "
UBUNTU_INSTALL="$DEBIAN_INSTALL"

usage='
cat >&2 << EOF

Usage: `basename $0` [OPTIONS] -d distribution
    -d  distribution
          debian        # $DEBIAN_BULLSEYE
          opensuse      # $OPENSUSE_LEAP
          redhat        # $REDHAT_UBI9
          ubuntu        # $UBUNTU_KINETIC
Options:
    -u  user                # (default derived from the shell)
    -n  name                # (default is "Admin User")
    -i  uid                 # (default derived from the shell)
    -p,-r "password sha"    # (default is "admin", "root" respectively)
        password sha can be generated offline: openssl passwd -[156] cleartext
    -o  output              # Docker directory (defaults to distribution name, will not overwrite)
    -t  tag                 # Docker image tagname
    -vimplugins "bundles"   # download vim pathogen and plugins from github e.g. -vimplugins "kien/ctrlp.vim,scrooloose/nerdtree,..."
    -rustcrates "crates"    # download the Rust compiler and build crates e.g. -rust "bat,ripgrep,..."

    -x  execute             # opportunity to execute the docker build on the completed directory
EOF
    exit 1
'

####################################################

#== Colors
# select graphic rendition 0=default, red, green, yellow, cyan, blue
#   infocmp -1 ansi | grep sgr0=
#   sgr0=\E[0;10m,
rt=$(tput sgr0); r=$(tput setaf 1); g=$(tput setaf 2); y=$(tput setaf 3); c=$(tput setaf 6); b=$(tput bold);

# capture the calling args and time
args="$0 $@"
calendar=`date "+%a %h %d    %D    Time: %r"`
timestamp=`date +.%Y%m%d_%H%M%S`



# where the user home files exists
# these are copied to the admin's home directory in the container
user_home_files=user_home
if [ ! -d $user_home_files ]; then
    echo "${r}Error:${rt} missing user home directory: $user_home_files"
    eval "$usage"
fi


# user defaults overwritable by options
USER=`id | sed -e 's,[^(]*(,,' -e 's,).*,,'`
USER_NAME='Admin User'
USER_UID=`id | sed -e 's,[^=]*=,,' -e 's,(.*,,'`
USER_SHA=`openssl passwd -1 admin`
ROOT_SHA=`openssl passwd -1 root`


# process the command line options
while :
do
    case $1 in
        -u)
            shift
            USER=$1
            ;;
        -n)
            shift
            USER_NAME=$1
            ;;
        -i)
            shift
            USER_UID=$1
            ;;
        -p)
            shift
            USER_SHA=$1
            ;;
        -d)
            shift
            dist_name=$1
            case $1 in
                debian)
                    docker_image=$DEBIAN_BULLSEYE
                    SUDO_GROUP=sudo
                    INSTALL="$DEBIAN_INSTALL"
                    ;;
                opensuse)
                    docker_image=$OPENSUSE_LEAP
                    SUDO_GROUP=wheel
                    INSTALL="$OPENSUSE_INSTALL"
                    ;;
                redhat)
                    docker_image=$REDHAT_UBI9
                    SUDO_GROUP=wheel
                    INSTALL="$REDHAT_INSTALL"
                    ;;
                ubuntu)
                    docker_image=$UBUNTU_KINETIC
                    SUDO_GROUP=sudo
                    INSTALL="$UBUNTU_INSTALL"
                    ;;
                *)
                    echo "${r}Error:${rt} distribution: [$1]"
                    eval "$usage"
            esac
            ;;
        -o)
            shift
            build_dir=$1
            ;;
        -r)
            shift
            ROOT_SHA=$1
            ;;
        -t)
            shift
            TAG_NAME=$1
            ;;
        -vimplugins)
            shift
            VIM_PLUGINS=$1
            ;;
        -rustcrates)
            shift
            RUST_CRATES=$1
            ;;
        -x)
            run_docker_build="yes"
            ;;
        -*)
            eval "$usage"
            ;;
        *)
            break
    esac
    shift
done

#############################
## Perform some sanity checks
#############################
if [ ! -z "$*" ]; then
    echo "${r}Error:${rt} unprocessed arguments:${y}$*${rt}"
    eval "$usage"
fi

if [ -z "$docker_image" ]; then
    echo "${r}Error:${rt} ${y}missing -d distribution${rt}"
    eval "$usage"
fi

# if -t tagname wasn't specified, use the image basename
if [ -z "$TAG_NAME" ]; then
    TAG_NAME=`echo "$docker_image" | sed 's,[/:].*,,'`
fi

# if -o  build_dir wasn't specified, use distribution name
if [ -z "$build_dir" ]; then
    build_dir=`echo "$docker_image" | sed 's,[/:],-,'`
fi

# never overwrite build_dir
if [ -d "$build_dir" ]; then
    echo "${r}Error:${rt} [${y}$build_dir${rt}] already exists"
    eval "$usage"
fi

# uid must be numeric
if [ `expr "$USER_UID" : '^[0-9][0-9]*$'` -eq 0 ]; then
    echo "${r}Error:${rt} invalid uid, must be numeric: [$USER_UID]"
    exit 1
fi

####################################################
# configure dynamic components
VIM_PLUGIN_CMD='echo "skipping Vim pathogen bundles"'
if [ ! -z "$VIM_PLUGINS" ]; then
    VIM_PLUGIN_CMD="mkdir -p /home/\$USER/.vim/autoload /home/\$USER/.vim/bundle && curl -LSso /home/\$USER/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim"

    OIFS=$IFS
    IFS=', ' # set space and comma as delimiters
    read -a plugins <<< "$VIM_PLUGINS"
    for plugin in ${plugins[@]}
    do
        VIM_PLUGIN_CMD="$VIM_PLUGIN_CMD && ( cd /home/\$USER/.vim/bundle && rm -rf `basename $plugin` && git clone https://github.com/${plugin}.git )"
    done
    IFS=$OIFS
    VIM_PLUGINS=${plugins[@]}
    VIM_PLUGINS=${VIM_PLUGINS// /,}
fi

RUST_CMD='echo "skipping Rust crates"'
if [ ! -z "$RUST_CRATES" ]; then
    OIFS=$IFS
    IFS=', ' # set space and comma as delimiters
    read -a crates <<< "$RUST_CRATES"
    IFS=$OIFS
    RUST_CMD="( curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y ) && \$HOME/.cargo/bin/cargo install ${crates[@]}"
    RUST_CRATES=${crates[@]}
    RUST_CRATES=${RUST_CRATES// /,}
fi

####################################################

# define the build command
build_cmd="docker build -t $TAG_NAME $build_dir"

# build a howto for this container
rerun="$(basename $0) -x -d $dist_name -u $USER -n '$USER_NAME' -i $USER_UID -p '$USER_SHA' -r '$ROOT_SHA' -o $build_dir -t $TAG_NAME -vimplugins '$VIM_PLUGINS' -rustcrates '$RUST_CRATES'"
howto_info=`cat << 'EOM'
echo "
##############################################################################################
#
# ${g}calendar: $calendar${rt}
# ${g}timestamp: $timestamp${rt}
# ${g}$rerun${rt}
#
# to build the container:
# ${g}$build_cmd${rt}

# to run the container exposing a shared directory and mapping localhost port 2222 to 22
# ${g}mkdir -p /tmp/shared && docker run -p 2222:22 -it -v /tmp/shared:/tmp/shared $TAG_NAME${rt}

# to connect to the running container as ${y}admin $USER${rt}
# ${g}ssh -p 2222 $USER@localhost${rt}
# ${g}ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error $USER@localhost${rt}

# to append a public key to ~$USER/.ssh/authorized_keys
# ${g}ssh-copy-id -p 2222 -i ~/.ssh/id_ed25519.pub $USER@localhost${rt}
##############################################################################################
"
EOM`

# turn off colors to build a comment for the Dockerfile from the howto
unset rt r g y c b
howto_comment=`eval "$howto_info"`

# create Dockerfile

# create the build_dir with user_home_files
mkdir -p $build_dir && (cd $user_home_files && tar cfj ../$build_dir/$user_home_files.tar.bz2 .)

cat > $build_dir/Dockerfile << EOD
FROM $docker_image
$howto_comment

ENV DEBIAN_FRONTEND=noninteractive

# the admin user
ENV USER='$USER'
ENV USER_NAME='$USER_NAME'
ENV USER_UID=$USER_UID
ENV USER_SHA='$USER_SHA'

# configure this box with a root password by modifying /etc/shadow with sed
ENV ROOT_SHA='$ROOT_SHA'
RUN sed -i "s,root:[^:]*:,root:\$ROOT_SHA:," /etc/shadow

# install packages, setup sudo, locale, system ssh host keys
RUN $INSTALL

########################
# setup the USER account
########################

# add the USER as a system user in group $SUDO_GROUP which has sudo ALL = (ALL) NOPASSWD: ALL
RUN useradd -r -m -d /home/\$USER -c "\$USER_NAME" -s /bin/bash -u \$USER_UID -g 100 -G $SUDO_GROUP -p "\$USER_SHA" \$USER

# become the USER
USER \$USER

# add USER home files
ADD --chown=\$USER:users user_home.tar.bz2 /home/\$USER/
RUN chgrp -R users /home/\$USER

########################
# dynamic builds
########################

RUN $VIM_PLUGIN_CMD
RUN $RUST_CMD

# install personal Rust utilites
RUN if [ -x \$HOME/.cargo/bin/cargo ]; then cd /tmp && git clone https://github.com/dfarnham/Rust.git && for d in b64 num sha utf8char uuid; do (cd "/tmp/Rust/\$d" && \$HOME/.cargo/bin/cargo install --path .); done; fi

###########################################
# switch back to the root user and run sshd
###########################################
USER root
RUN if [ -x /usr/sbin/slapd ]; then echo "alias startldap=\"/usr/sbin/slapd -h 'ldap:/// ldapi:/// ldaps:///' -g openldap -u openldap -F /etc/ldap/slapd.d\"" >> /root/.bashrc; fi
WORKDIR /root
ENTRYPOINT /usr/sbin/sshd && /bin/bash
EOD

####################################################

# assign the color variables
rt=$(tput sgr0); r=$(tput setaf 1); g=$(tput setaf 2); y=$(tput setaf 3); c=$(tput setaf 6); b=$(tput bold);

# display build information
cat << INFO
# ===========================================
# $build_dir/Dockerfile -- $docker_image
# ===========================================
# USER=$USER
# USER_NAME=$USER_NAME
# USER_UID=$USER_UID
# USER_SHA=$USER_SHA
# ROOT_SHA=$ROOT_SHA
INFO

if [ ! -z "$VIM_PLUGINS" ]; then
    echo \# Vim plugins: ~${USER}/.vim/bundle: $VIM_PLUGINS
fi
if [ ! -z "$RUST_CRATES" ]; then
    echo \# Rust crates: ~${USER}/.cargo/bin: $RUST_CRATES
fi

####################################################

# ask to run docker build
if [ "$run_docker_build" = "yes" ]; then
    echo
    echo press "${g}enter${rt} to ${y}\"docker build -t $TAG_NAME $build_dir\"${rt} or ${r}ctrl-c${rt} to quit and inspect ${y}$build_dir/Dockerfile${rt}"
    read answer
    eval "$build_cmd"
fi

# display the colorized howto if the build succeeded
if [ $? -eq 0 ]; then
    eval "$howto_info"
fi
