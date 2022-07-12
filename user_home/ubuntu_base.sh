#!/bin/sh

#cat << EODOCKER
docker build -t ubuntu - << EODOCKER
FROM ubuntu:kinetic

# the admin user
ENV USER=`whoami`
ENV USER_NAME='Admin User'
ENV USER_UID=`id -u`
ENV USER_SHA='`openssl passwd -1 admin`'

# install minimum bootstrap packages
RUN apt-get update && apt-get -y install curl openssh-client openssh-server python3 sudo zip && mkdir /run/sshd && ssh-keygen -A
    
# add the USER as a system user in group %sudo ALL=(ALL:ALL) ALL
RUN useradd -r -m -d /home/\$USER -c "\$USER_NAME" -s /bin/bash -u \$USER_UID -g 100 -G sudo -p "\$USER_SHA" $USER

# add USER home files from my github Docker-Linux "user_home" subdirectory
RUN curl -LSso /tmp/main.zip https://github.com/dfarnham/Docker-Linux/archive/refs/heads/main.zip && unzip -d /tmp /tmp/main.zip && bash -c 'mv /tmp/Docker-Linux-main/user_home/{*,.[a-zA-Z]*} /home/\$USER' && rm -rf /tmp/main.zip /tmp/Docker-Linux-main
RUN chown -R \$USER /home/\$USER

WORKDIR /root
ENTRYPOINT /usr/sbin/sshd && /bin/bash
EODOCKER
