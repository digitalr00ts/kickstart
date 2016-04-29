#!/bin/bash
if [ ! -z ${1+x} ] ; then
  if [ $1 = 'test' ] ; then
    runpath='.'
    blockdevice='vda'
  else
    disk=$1
  fi
elif [ -n '$blockdevice' ] ; then
  disk=$blockdevice
else
  echo "no block device" >&2
  exit 1
fi

[ -z ${runpath+x} ] && declare -x runpath='/run/install'
file=${runpath}/partitions.ks

echo "# Generated partition scheme for $disk" > $file
echo "clearpart --drives=$disk" >> $file
[ $disk == vda ] && echo "zerombr" >> $file
echo "bootloader --boot-drive=$disk --timeout=1" >> $file

# echo "autopart --type=lvm --fstype=ext4" >> $file
# --add-boot may cause Anaconda to crash when explicitly creating /boot
echo "reqpart" >> $file

echo "part /boot --recommended --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,filetype,sparse_super,flex_bg,uninit_bg,resize_inode -I 256 -N 1000\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async,stripe=4\" --label=boot --ondrive=$disk" >> $file
echo "part pv.01 --grow --ondrive=$disk" >> $file
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
