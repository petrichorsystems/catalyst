#! /bin/bash

wipefs -a /dev/sda
parted -s -a optimal /dev/sda mklabel gpt
parted -s -a optimal /dev/sda unit mib
parted -s -a optimal /dev/sda mkpart primary 1 3
parted -s -a optimal /dev/sda name 1 grub
parted -s -a optimal /dev/sda set 1 bios_grub on
parted -s -a optimal /dev/sda mkpart primary 3 131
parted -s -a optimal /dev/sda name 2 boot
parted -s -a optimal /dev/sda mkpart primary 131 643
parted -s -a optimal /dev/sda name 3 swap
parted -s -a optimal /dev/sda mkpart primary 643 -1
parted -s -a optimal /dev/sda name 4 rootfs
parted -s -a optimal /dev/sda set 2 boot on

mkfs.ext2 /dev/sda2
mkfs.ext4 /dev/sda4
mkswap /dev/sda3
swapon /dev/sda3

mount /dev/sda4 /mnt/gentoo

ntpd -q -g

cd /mnt/gentoo

wget https://gentoo.osuosl.org/releases/amd64/autobuilds/latest-stage3.txt
CURRENT_STAGE3=`cat latest-stage3.txt | cut -d'/' -f2 | cut -d' ' -f1 | grep -v '#' | sed -n 1p`
wget https://gentoo.osuosl.org/releases/amd64/autobuilds/current-stage3-amd64/$CURRENT_STAGE3
tar xvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm latest-stage3.txt

sed -i 's/COMMON_FLAGS=.*/COMMON_FLAGS="-O2 -march=native -pipe"/' /mnt/gentoo/etc/portage/make.conf 
PHYSICAL_CORES=$(( $(lscpu | awk '/^Socket/{ print $2 }') * $(lscpu | awk '/^Core/{ print $4 }') +1))
echo MAKEOPTS=\"-j$PHYSICAL_CORES\" >> /mnt/gentoo/etc/portage/make.conf

echo 'GENTOO_MIRRORS="http://www.gtlib.gatech.edu/pub/gentoo https://gentoo.osuosl.org/"' >> /mnt/gentoo/etc/portage/make.conf

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir /boot
mount /dev/sda2 /boot

emerge-webrsync
emerge --ask --verbose --update --deep --newuse @world

echo 'USE="-X -kde -gnome -pulseaudio alsa jack midi mp3 dbus osc"' >> /mnt/gentoo/etc/portage/make.conf

echo "US/Pacific" > /etc/timezone

sed -i 's/#en_US ISO-8859-1.*/en_US ISO-8859-1/' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8.*/en_US.UTF-8 UTF-8/' /etc/locale.gen

locale-gen
eselect locale set 4

env-update && source /etc/profile && export PS1="(chroot) $PS1"

emerge sys-kernel/rt-sources

emerge sys-apps/pciutils

cd /usr/src/linux
# copy linux config from temp location to here

make && make modules_install
make install

emerge sys-kernel/linux-firmware

sed -i 's/hostname="localhost".*/hostname="silica"/' /etc/conf.d/hostname

emerge --noreplace net-misc/netifrc

echo 'config_enp2s0="dhcp"' >> /etc/conf.d/net

cd /etc/init.d
ln -s net.lo net.enp2s0
rc-update add net.enp2s0 default

echo 'root:silica' | chpasswd

emerge sys-apps/mlocate

rc-update add sshd default

emerge sys-fs/e2fsprogs sys-fs/xfsprogs sys-fs/reiserfsprogs sys-fs/jfsutils sys-fs/dosfstools

emerge net-misc/dhcpcd

emerge --verbose sys-boot/grub:2
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G users,wheel,audio -s /bin/bash silica
echo 'silica:silica' | chpasswd

rm /stage3-*.tar.xz*

exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot
