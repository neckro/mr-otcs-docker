#!/bin/bash

if [[ "$( arch )" != "aarch64" ]]; then
    echo "This doesn't seem to be ARM."
    exit
fi

cd /usr/local/src
git clone --depth 1 https://github.com/raspberrypi/userland.git
cd /usr/local/src/userland
./buildme

echo "/opt/vc/lib" > /etc/ld.so.conf.d/00-vmcs.conf
ldconfig
