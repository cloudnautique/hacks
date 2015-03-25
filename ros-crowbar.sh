#!/bin/bash

apt-get update
apt-get install -y curl git

mkdir -p /lib/rancher/conf

e2label /dev/sda1 RANCHER_STATE

cat > /lib/rancher/conf/rancher.yml<<EOF
cloud_init:
  datasources:
      - file:/var/lib/rancher/conf/user_config.yml
EOF

cat > /lib/rancher/conf/user_config.yml<<EOF
#cloud-config
ssh_authorized_keys:
  - $(<key.pub)
rancher:
  network:
    interfaces:
      eth*:
        dhcp: true
        mtu: 1460
      lo:
        address: 127.0.0.1/8
EOF

cd /boot
curl -L -o vmlinuz-rancheros-0.2.1 https://github.com/rancherio/os/releases/download/v0.2.1/vmlinuz
curl -L -o initrd-rancheros-0.2.1 https://github.com/rancherio/os/releases/download/v0.2.1/initrd

cat<<EOF
menuentry 'RancherOS-v0.2.1' {
        load_video
        insmod gzio
        insmod part_msdos
        insmod ext2
        set root='(/dev/mapper/vda,msdos1)'
        search --no-floppy --fs-uuid --set=root ea795a0f-394e-4ced-952b-0fd0e3ab762c
        echo    'Loading RancherOS ...'
        linux   /boot/vmlinuz-rancheros-0.2.1 rancher.password=rancher rancher.debug=true ro console=ttyS0,38400n8 console=ttyS0
        echo    'Loading initial ramdisk ...'
        initrd  /boot/initrd-rancheros-0.2.1
}
EOF
