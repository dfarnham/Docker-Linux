#!/bin/sh

if [ -x /usr/bin/expect -o -x /usr/local/bin/expect ]; then
    if [ -x /usr/bin/expect ]; then
        ls -l /usr/bin/expect
    else
        ls -l /usr/local/bin/expect
    fi
    exit 0
fi

if [ -f /tmp/shared/expect5.45.4.tar.gz -a -f /tmp/shared/tcl8.6.12-src.tar.gz ]; then
    cd /tmp
    tar xfz /tmp/shared/expect5.45.4.tar.gz
    tar xfz /tmp/shared/tcl8.6.12-src.tar.gz

    cd /tmp/tcl8.6.12/unix
    ./configure && sudo make install

    cd /tmp/expect5.45.4
    ./configure --build=x86_64 && sudo make install
fi
