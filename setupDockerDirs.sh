#!/bin/bash
#
# dwf -- initial
# Fri Jun 17 22:36:41 MDT 2022

#== Colors
rt=$(tput sgr0); r=$(tput setaf 1); g=$(tput setaf 2); y=$(tput setaf 3); c=$(tput setaf 6); b=$(tput bold);

invoked="$0 $@"
timestamp=`date +.%Y%m%d_%H%M%S`

# current supported distributions by this script
OPENSUSE_LEAP='opensuse/leap'
OPENSUSE_DEFAULT_TAG=`echo "$OPENSUSE_LEAP" | sed 's,[/:].*,,'`

REDHAT_UBI8='redhat/ubi8'
REDHAT_DEFAULT_TAG=`echo "$REDHAT_UBI8" | sed 's,[/:].*,,'`

UBUNTU_KINETIC='ubuntu:kinetic'
UBUNTU_DEFAULT_TAG=`echo "$UBUNTU_KINETIC" | sed 's,[/:].*,,'`

# where the user home files exists
user_home_files=user_home

usage='
cat >&2 << EOF

Usage: `basename $0` [OPTIONS] -d distribution
    -d  distribution        # distribution to build
          opensuse - $OPENSUSE_LEAP
          redhat   - $REDHAT_UBI8
          ubuntu   - $UBUNTU_KINETIC
Options:
    -u  user                # (default derived from the shell)
    -n  name                # (default is "Admin User")
    -i  uid                 # (default derived from the shell)
    -p,-r "password sha"    # (default is "admin", "root" respectively)
        password sha can be generated offline: openssl passwd -[156] cleartext
    -o  output              # Docker directory (defaults to distribution name, will not overwrite)
    -t  tag                 # Docker image tagname
    -vimplugins "bundles"   # download vim pathogen and plugins from github e.g. -vimplugins "kien/ctrlp.vim scrooloose/nerdtree ..."
    -rustcrates "crates"    # download the Rust compiler and build crates e.g. -rust "bat ripgrep ..."

    -x  execute             # opportunity to execute the docker build on the completed directory
EOF
    exit 1
'

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
            case $1 in
                opensuse)
                    docker_image=$OPENSUSE_LEAP
                    ;;
                redhat)
                    docker_image=$REDHAT_UBI8
                    ;;
                ubuntu)
                    docker_image=$UBUNTU_KINETIC
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

########################
## More Sanity Checks ##
########################
if [ -z "$docker_image" ]; then
    #echo "$(tput setaf 3)Error: missing -d distribution$(tput setaf 1)"
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
    echo "${r}Error:${rt} [$build_dir] already exists"
    eval "$usage"
fi

# uid must be numeric
if [ `expr "$USER_UID" : '^[0-9][0-9]*$'` -eq 0 ]; then
    echo "${r}Error:${rt} invalid uid, must be numeric: [$USER_UID]"
    exit 1
fi

# create the build_dir with user_home_files
mkdir -p $build_dir && (cd $user_home_files && tar cfj ../$build_dir/$user_home_files.tar.bz2 .)

# setup sudo group and package install
#   sudo groups and /etc/sudoers vary by distribution
#   package installers vary by distribution
#
# installing a set of workable packages I desire for each distribution and
# maintaining custom utility portability across architectures is fluid
shared_pkg_names='curl gcc git jq less make man perl rsync sudo vim'

if [ $docker_image = $OPENSUSE_LEAP ]; then
    SUDO_GROUP=wheel
    PKG_INSTALL="zypper refresh && zypper -n install $shared_pkg_names man-pages openssh perl python39 tree && groupadd wheel && ln -s /usr/bin/python3.9 /usr/bin/python3"
    FIX_SUDOERS='sed -i "s,# %wheel,%wheel," /etc/sudoers'
    HOST_SSH_KEYS='ssh-keygen -A'
elif [ $docker_image = $REDHAT_UBI8 ]; then
    SUDO_GROUP=wheel
    PKG_INSTALL="yum -y install $shared_pkg_names glibc-langpack-en man-db openssh-clients openssh-server perl-encoding procps python39"
    FIX_SUDOERS='sed -i "s,# %wheel,%wheel," /etc/sudoers'
    HOST_SSH_KEYS='ssh-keygen -A'
elif [ $docker_image = $UBUNTU_KINETIC ]; then
    SUDO_GROUP=sudo
    PKG_INSTALL="apt-get update && apt-get -y install $shared_pkg_names man-db openssh-client openssh-server man-db perl python3 r-base tree"
    FIX_SUDOERS='sed -i "s,%sudo.*,%sudo ALL=(ALL:ALL) NOPASSWD: ALL," /etc/sudoers'
    HOST_SSH_KEYS='mkdir /run/sshd && ssh-keygen -A'
else
    echo "Bug! Docker image not matched: [$docker_image]"
    echo "Bug! Distrubtions: [$OPENSUSE_LEAP] [$REDHAT_UBI8] [$UBUNTU_KINETIC]"
    exit 1
fi

# configure dynamic components
if [ ! -z "$VIM_PLUGINS" ]; then
    VIM_PLUGIN_CMD="mkdir -p /home/\$USER/.vim/autoload /home/\$USER/.vim/bundle && curl -LSso /home/\$USER/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim"
    for plugin in $VIM_PLUGINS
    do
        VIM_PLUGIN_CMD="$VIM_PLUGIN_CMD && (cd /home/\$USER/.vim/bundle && rm -rf `basename $plugin` && git clone https://github.com/${plugin}.git)"
    done
else
    VIM_PLUGIN_CMD='echo "skipping vim pathogen and bundles"'
fi

if [ ! -z "$RUST_CRATES" ]; then
    RUST_CMD="(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y) && \$HOME/.cargo/bin/cargo install $RUST_CRATES"
else
    RUST_CMD='echo "skipping Rust and crates"'
fi

# create Dockerfile
build_cmd="docker build -t $TAG_NAME $build_dir"
#unset rt r g y c b
cat > $build_dir/Dockerfile << EOD
FROM $docker_image

ENV DEBIAN_FRONTEND=noninteractive

##############################################################################################
#
# timestamp: $timestamp
# $invoked
#
# to build the container:
# $build_cmd

# to run the container exposing a shared directory and mapping localhost port 2222 to 22
# mkdir -p /tmp/shared && docker run -p 2222:22 -it -v /tmp/shared:/tmp/shared $TAG_NAME

# to connect to the running container as admin $USER
# ssh -p 2222 $USER@localhost
# ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error $USER@localhost

##############################################################################################

# the admin user
ENV USER='$USER'
ENV USER_NAME='$USER_NAME'
ENV USER_UID=$USER_UID
ENV USER_SHA='$USER_SHA'

# configure this box with a root password by modifying /etc/shadow with sed
ENV ROOT_SHA='$ROOT_SHA'
RUN sed -i "s,root:[^:]*:,root:\$ROOT_SHA:," /etc/shadow

# install packages
RUN $PKG_INSTALL

# generate system ssh host keys (requires openssh installed)
RUN $HOST_SSH_KEYS

########################
# setup the USER account
########################

# add the USER as a system user in group $SUDO_GROUP which has sudo ALL = (ALL) NOPASSWD: ALL
RUN useradd -r -m -d /home/\$USER -c "\$USER_NAME" -s /bin/bash -u \$USER_UID -g 100 -G $SUDO_GROUP -p "\$USER_SHA" \$USER

# modify /etc/sudoers
RUN $FIX_SUDOERS

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
WORKDIR /root
ENTRYPOINT /usr/sbin/sshd && /bin/bash
EOD

echo \# ===========================================
echo \# $build_dir/Dockerfile -- $docker_image
echo \# ===========================================
echo \# USER=$USER
echo \# USER_NAME=$USER_NAME
echo \# USER_UID=$USER_UID
echo \# USER_SHA=$USER_SHA
echo \# ROOT_SHA=$ROOT_SHA
if [ ! -z "$VIM_PLUGINS" ]; then
    echo \# Vim plugins: ~${USER}/.vim/bundle: $VIM_PLUGINS
fi
if [ ! -z "$RUST_CRATES" ]; then
    echo \# Rust crates: ~${USER}/.cargo/bin: $RUST_CRATES
fi

if [ "$run_docker_build" = "yes" ]; then
    echo press "${g}enter${rt} to ${y}\"docker build -t $TAG_NAME $build_dir\"${rt} or ${r}ctrl-c${rt} to quit and inspect ${y}$build_dir/Dockerfile${rt}"
    read answer
    eval "$build_cmd"
fi

if [ $? -eq 0 ]; then
    echo
    echo "# to build the container"
    echo "${g}docker build -t $TAG_NAME $build_dir${rt}"
    echo
    echo "# to run the container exposing a shared directory and mapping localhost port 2222 to 22"
    echo "${g}mkdir -p /tmp/shared && docker run -p 2222:22 -it -v /tmp/shared:/tmp/shared $TAG_NAME${rt}"
    echo
    echo "# to connect to the running container as admin $USER"
    echo "${g}ssh -p 2222 $USER@localhost${rt}"
    echo "     or"
    echo "${g}ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error $USER@localhost${rt}"
fi
