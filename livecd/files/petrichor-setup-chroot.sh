#! /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir /boot
mount /dev/sda2 /boot

emerge-webrsync
emerge --verbose --update --deep --newuse @world

echo 'USE="-X -kde -gnome -pulseaudio alsa jack midi mp3 dbus osc"' >> /etc/portage/make.conf

echo "US/Pacific" > /etc/timezone

sed -i 's/#en_US ISO-8859-1.*/en_US ISO-8859-1/' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8.*/en_US.UTF-8 UTF-8/' /etc/locale.gen

locale-gen
eselect locale set 4

env-update && source /etc/profile && export PS1="(chroot) $PS1"

mkdir -p /etc/portage/package.accept_keywords/sys-kernel/
echo "sys-kernel/rt-sources ~amd64" >> /etc/portage/package.accept_keywords/sys-kernel/rt-sources
emerge sys-kernel/rt-sources

emerge sys-apps/pciutils

cd /usr/src/linux
cp /etc/petrichor_setup/petrichor.linux.config /usr/src/linux/.config

make && make modules_install
make install

emerge sys-kernel/linux-firmware

cp /etc/petrichor_setup/petrichor.linux.fstab /etc/fstab

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
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G users,wheel,audio -s /bin/bash silica
echo 'silica:silica' | chpasswd

rm /stage3-*.tar.xz*

exit
