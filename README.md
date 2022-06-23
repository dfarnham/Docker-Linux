# Docker-Linux &emsp; ![Latest Version]

[Latest Version]: https://img.shields.io/badge/Docker_Linux-v0.1.0-blue

### Generates Dockerfiles for Linux distributions **Debian**, **openSUSE**, **RedHat**, **Ubuntu**
#### Common tooling with a configured admin account

Features:

* Distributions are configured with a sudo account populated from files placed in **user_common**
* The containers accept **ssh connections**
* Common tools installed for each distribution (**curl**, **gcc**, **git**, **jq**, **less**, **man**, **openssh**, **perl**, **python3**, **sudo**, **vim**)
* **Vim plugins** can be downloaded from github
* **Rust crates** can be installed
* *If Rust is installed so are my Rust tools from github ( **b64**, **num**, **sha**, **utf8char**, **uuid** )*

---

To create the Docker build directories run **buildDockerDirs.sh**:

~~~sh
# create the build directory for each distribution with defaults
buildDockerDirs.sh -d debian
buildDockerDirs.sh -d opensuse
buildDockerDirs.sh -d redhat
buildDockerDirs.sh -d ubuntu
~~~

---

The **user_common** directory contains files and utilities which will be copied to the user account

~~~sh
user_home/
├── .bash_logout
├── .bash_profile
├── .bashrc
├── .ssh
│   └── authorized_keys
├── .vars
├── .vim
│   └── colors
│       └── dave.vim
├── .vimrc
└── bin
    ├── chop
    ├── corr.pl
    ├── cutcol.pl
    ├── detab
    ├── endian
    ├── exp
    ├── fp
    ├── hexbytes
    ├── imgcat
    ├── ip2hex
    ├── lst
    ├── md5
    ├── ncol.pl
    ├── prec
    ├── rename.pl
    ├── rpm.help
    ├── rsy
    ├── rsyd
    ├── sed.help
    ├── sort.pl
    ├── trim
    ├── unexp -> exp
    └── vars
~~~

---

The **-x** option will prompt to issue the **docker build** command

~~~sh
buildDockerDirs.sh -x -d ubuntu
...
press enter to "docker build -t ubuntu ubuntu-kinetic" or ctrl-c to quit and inspect ubuntu-kinetic/Dockerfile
~~~

---

**buildDockerDirs.sh** has a few configurable options

~~~sh
Usage: buildDockerDirs.sh [OPTIONS] -d distribution
    -d  distribution        # distribution to build
          debian   - debian:bullseye
          opensuse - opensuse/leap
          redhat   - redhat/ubi9
          ubuntu   - ubuntu:kinetic
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
~~~

---

A configured build example:

~~~sh
buildDockerDirs.sh -x -d ubuntu \
	-u dave \
	-p `openssl passwd -6 testing` \
	-t ubu-test \
	-o ubu-test-build
	-vimplugins "kien/ctrlp.vim scrooloose/nerdtree rust-lang/rust.vim godlygeek/tabular" \
	-rustcrates "bat fd-find ripgrep bottom hyperfine"
	
# ===========================================
# ubu-test-build/Dockerfile -- ubuntu:kinetic
# ===========================================
# USER=dave
# USER_NAME=Admin User
# USER_UID=501
# USER_SHA=$6$L6GCgRW84DT9cMwD$N3QK1aWhwe6yWByb1LBo1x8X90enztYh0D1W2QfRYlSY40DdWlIWPnRrJtIMDonYX2tiXFTrPxVxRespoqPTR.
# ROOT_SHA=$1$41xRE6VK$iMWOB65mjIiB6raJ/NghV.
# Vim plugins: ~dave/.vim/bundle: kien/ctrlp.vim scrooloose/nerdtree rust-lang/rust.vim godlygeek/tabular
# Rust crates: ~dave/.cargo/bin: bat fd-find ripgrep bottom hyperfine
press enter to "docker build -t ubu-test ubu-test-build" or ctrl-c to quit and inspect ubu-test-build/Dockerfile

... [docker build completes] ...

# to build the container
docker build -t ubu-test ubu-test-build

# to run the container exposing a shared directory and mapping localhost port 2222 to 22
mkdir -p /tmp/shared && docker run -p 2222:22 -it -v /tmp/shared:/tmp/shared ubu-test

# to connect to the running container as admin dave
ssh -p 2222 dave@localhost
     or
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error dave@localhost

# to append your public key to ~/.ssh/authorized_keys
ssh-copy-id -p 2222 -i ~/.ssh/id_ed25519.pub dave@localhost
~~~

---

# **Persisting** changes to a running container

(from shell 1, no containers running)
----
~~~sh
from shell 1, no containers running)
------------------------------------
$ docker container ls
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

(list available images)
$ docker images
REPOSITORY     TAG       IMAGE ID       CREATED         SIZE
ubu-test       latest    653b03d1edbd   5 minutes ago   2.89GB
redhat         latest    8c8b74ae2f2e   5 hours ago     2.34GB
opensuse       latest    cc8b961e0b01   5 hours ago     2.53GB
ubuntu         latest    caa144d5b7c3   5 hours ago     2.9GB

Run a container
$ mkdir -p /tmp/shared && docker run -p 2222:22 -it -v /tmp/shared:/tmp/shared ubu-test
root@0ddcfe629c2f:~#
~~~

---

(from shell 2, connect - display sudo privs -- write a file)
----
~~~sh
from shell 2, connect - display sudo privs -- write a file
----------------------------------------------------------
$ docker ps -l   # or  container ls
CONTAINER ID   IMAGE      COMMAND                  CREATED              STATUS              PORTS                  NAMES
0ddcfe629c2f   ubu-test   "/bin/sh -c '/usr/sb…"   About a minute ago   Up About a minute   0.0.0.0:2222->22/tcp   jovial_cray

$ ssh -p 2222 dave@localhost
Welcome to Ubuntu Kinetic Kudu (development branch) (GNU/Linux 5.10.104-linuxkit x86_64)
...

1: 0 ✓ dave@0ddcfe629c2f:~$>id
uid=501(dave) gid=100(users) groups=100(users),27(sudo)

2: 0 ✓ dave@0ddcfe629c2f:~$>sudo -l
Matching Defaults entries for dave on 0ddcfe629c2f:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty

User dave may run the following commands on 0ddcfe629c2f:
    (ALL : ALL) NOPASSWD: ALL
    
3: 0 ✓ dave@0ddcfe629c2f:~$>echo 'persisted data' > keepme
~~~

---

(from shell 3, view data in the running container - commit changes)
----
~~~sh
from shell 3, view data in the running container - commit changes
-----------------------------------------------------------------
$ ssh -p 2222 dave@localhost cat keepme  # show it's in the running container
persisted data

Commit the changes (modifying ubu-test)
$ docker commit 0ddcfe629c2f ubu-test
sha256:653b03d1edbd3fae69aeb0197ec5000f61e414e95e054f4c4173473a84ec394f

... [many changes later] ...
Write the entire image to a file, load on another machine (similar architecture)

Find the image id ( docker images )
1. docker save 0177ce6d2533 > 0177ce6d2533.tar
2. scp 0177ce6d2533.tar some_machine:
3. docker load < 0177ce6d2533.tar
~~~





