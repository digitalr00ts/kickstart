#!/bin/bash
[ -z ${runpath+x} ] && declare -x runpath='/run/install'
[ $2 = 'test' ] && runpath='.'
file=${runpath}/partitions.ks

if [ -n $1 ] ; then
  disk=$blockdevice
elif [ -n '$blockdevice' ] ; then
  disk=$1
else
  echo "no block device" >&2
  exit 1
fi

echo "# Generated partition scheme for $disk" > $file
echo "clearpart --drives=$disk" >> $file
[ $disk == vda ] && echo "zerombr" >> $file
echo "bootloader --boot-drive=$disk --timeout=1" >> $file

# echo "autopart --type=lvm --fstype=ext4" >> $file
# --add-boot may cause Anaconda to crash when explicitly creating /boot
echo "reqpart" >> $file

echo "part /boot --recommended --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,filetype,sparse_super,flex_bg,uninit_bg,resize_inode -I 256 -N 1000\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async,stripe=4\" --label=boot --ondrive=$drive" >> $file
echo "part pv.01 --grow --ondrive=$drive" >> $file
echo "volgroup vg_$disk pv.01" >> $file
echo "logvol swap --$([ ! $disk == 'vda' ] && echo 'hibernation' || echo 'recommended') --vgname=vg_$disk --name=lv_swap --fstype=swap --label=swap --size=512" >> $file
echo "logvol none --vgname=vg_$disk --name=lv_$disk --thinpool --size=1000 --grow" >> $file
echo "logvol / --vgname=vg_$disk --name=lv_root --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,dir_nlink,resize_inode -I 256 -i 32768\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async\" --label=root --size=8000 --thin --poolname=lv_$disk" >> $file
echo "logvol /home --vgname=vg_$disk --name=lv_home --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 256 -i 32768\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --label=var --size=10000 --thin --poolname=lv_$disk" >> $file
echo "logvol /var --vgname=vg_$disk --name=lv_var --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 256 -i 32768\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --label=home --size=2000 --thin --poolname=lv_$disk" >> $file

echo >> $file
echo "# packages based on block device" >> $file
echo "%packages" >> $file
echo "$([ $disk != 'vda' ] && echo '-')qemu-guest-agent" >> $file
echo "%end" >> $file
