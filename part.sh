#!/bin/bash

disk=''
file='/run/install/part.ks'

if [ -d /sys/block/vda ] ; then
  disk=vda
elif [ -d /sys/block/sda ] ; then
  disk=sda
else
  echo "No block device that I am expecting"
  return 1
fi

echo "# Generated partition scheme for $disk" > $file
[ $disk == vda ] && echo "zerombr" >> $file
echo "clearpart --initlabel --drives=$disk --all --disklabel=system" >> $file
echo "part /boot --fstype=ext4 --mkfsoptions=\"-Onone,extent,filetype,sparse_super,flex_bg,uninit_bg,resize_inode -I 128 -N 1000\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async,stripe=4\"--recommended --label=boot --asprimary --ondrive=$drive" >> $file
echo "part pv.01 --grow --ondrive=$drive" >> $file 
echo "volgroup vg_$disk pv.01" >> $file
echo "logvol swap --hibernation --label=swap" >> $file
echo "logvol none --thinpool --profile=thin-performance --grow --name=lv_$disk" >> $file
echo "logvol / --vgname=vg_$disk --size=8000 --thin --poolname=lv_$disk --fstype=ext4 --mkfsoptions=\"-Onone,extent,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,dir_nlink,resize_inode -I 128 -i 32768\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async\" --label=lv_root" >> $file
echo "logvol /var --vgname=vg_$disk --size=2000 --thin --poolname=lv_$disk --fstype=ext4 --mkfsoptions=\"-Onone,extent,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 128 -i 32768\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --label=lv_var" >> $file
echo "logvol /home --vgname=vg_$disk --size=8000 --thin --poolname=lv_$disk --fstype=ext4 --mkfsoptions=\"-Onone,extent,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 128 -i 32768\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --label=lv_home" >> $file
