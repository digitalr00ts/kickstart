#!/bin/bash

disk=''
file='/run/install/disk.ks'

if [ -d /sys/block/vda ] ; then
  disk=vda
elif [ -d /sys/block/sda ] ; then
  disk=sda
else
  echo "No block device that I am expecting"
  return 1
fi

echo "# Generated partition scheme for $disk" > $file
echo "clearpart --drives=$disk" >> $file
[ $disk == vda ] && echo "zerombr" >> $file
echo "bootloader --boot-drive=$disk --timeout=1" >> $file

# echo "autopart --type=lvm --fstype=ext4" >> $file
# echo "reqpart --add-boot" >> $file

# echo "part /boot --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,filetype,sparse_super,flex_bg,uninit_bg,resize_inode -I 256 -N 1000\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async,stripe=4\" --recommended --label=boot --asprimary --ondrive=$drive" >> $file
echo "part /boot --recommended --ondrive=$drive" >> $file
echo "part pv.01 --grow --ondrive=$drive" >> $file
echo "volgroup vg$disk pv.01" >> $file
# echo "logvol swap --hibernation --fstype=swap --size=1000 --vgname=vg_$disk --label=swap --name=lv_swap" >> $file
echo "logvol swap --vgname=vg$disk --name=lvswap --fstype=swap --size=512" >> $file
echo "logvol none --vgname=vg$disk --name=lv$disk --thinpool --size=5000 --grow" >> $file
echo "logvol / --vgname=vg$disk --name=lvroot --size=2000 --thin --poolname=lv$disk" >> $file
echo "logvol /var --vgname=vg$disk --name=lvvar --size=1000 --thin --poolname=lv$disk" >> $file
# echo "logvol / --vgname=vg_$disk --size=8000 --thin --poolname=lv_$disk --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,dir_nlink,resize_inode -I 256 -i 32768\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async\" --label=root --name=lv_root" >> $file
# echo "logvol /var --vgname=vg_$disk --size=2000 --thin --poolname=lv_$disk --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 256 -i 32768\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --label=var --name=lv_var" >> $file
# echo "logvol /home --vgname=vg_$disk --size=8000 --thin --poolname=lv_$disk --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 256 -i 32768\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --label=home --name=lv_home" >> $file

echo >> $file
echo "# packages based on block device" >> $file
echo "%packages" >> $file
echo "$([ $disk != 'vda' ] && echo '-')qemu-guest-agent" >> $file
echo "%end" >> $file
