#!/bin/bash

apt-get update
apt-get install -y curl git
if [ ! $(command -v docker) ]; then
    curl -sSL https://get.docker.com|sh
fi

if [ ! -d ./os ]; then
    git clone https://github.com/cloudnautique/os.git
    cd os
    git checkout gce_image 
    git merge --no-commit --no-ff origin/more_logging_with_a_side_of_debug
else
    cd os
fi

./build.sh
cd ..

mkdir -p /lib/rancher/conf

e2label /dev/sda1 RANCHER_STATE

cp os/dist/artifacts/vmlinuz /boot/vmlinuz-rancheros-0.2.1
cp os/dist/artifacts/initrd /boot/initrd-rancheros-0.2.1


cat<<EOF
menuentry 'RancherOS-v0.2.1' {
        load_video
        insmod gzio
        insmod part_msdos
        insmod ext2
        set root='(/dev/mapper/vda,msdos1)'
        search --no-floppy --fs-uuid --set=root --label RANCHER_STATE RANCHER_BOOT
        echo    'Loading RancherOS ...'
        linux   /boot/vmlinuz-rancheros-0.2.1 rancher.oem=gce rancher.cloud_init.datasources=[gce] rancher.debug=true console=ttyS0
        echo    'Loading initial ramdisk ...'
        initrd  /boot/initrd-rancheros-0.2.1
}
EOF
