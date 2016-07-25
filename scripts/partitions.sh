#!/bin/bash
if [ ! -z ${1+x} ] ; then
  if [ $1 = 'test' ] ; then
    runpath='.'
    disk1='vda'
    disk2='vdb'
  elif ([ $1 = 'two' ] && [ -n $blockdevice ]) ; then
    [ "$blockdevice" == 'vda' ] && disk2='vdb'
    [ "$blockdevice" == 'sda' ] && disk2='sdb'
    [ "$blockdevice" == 'hda' ] && disk2='hdb'
    disk1=$blockdevice
  else
    disk1=$1
    disk2=$1
  fi
elif [ -n $blockdevice ] ; then
  disk1=$blockdevice
  disk2=$blockdevice
else
  echo "no block device" >&2
  exit 1
fi

[ -z ${runpath+x} ] && declare -x runpath='/run/install'
file=${runpath}/partitions.ks

echo "# Generated partition scheme for $disk2" > $file
echo "clearpart --drives=$disk1$([ "$disk1" != "$disk2" ] && (echo ",${disk2}"))" >> $file
# [ "$disk1" = 'vda' ] && echo "zerombr" >> $file
echo "zerombr" >> $file
echo "bootloader --boot-drive=$disk2 --timeout=1" >> $file

# echo "autopart --type=lvm --fstype=ext4" >> $file
# --add-boot may cause Anaconda to crash when explicitly creating /boot
echo "reqpart" >> $file
echo >> $file
echo '# boot ### ### ###' >> $file
echo "part /boot --recommended --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,filetype,sparse_super,flex_bg,uninit_bg,resize_inode -I 256 -N 1000\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async,stripe=4\" --ondrive=$disk2" >> $file
echo >> $file
echo '# physical volume ### ### ###' >> $file
echo "part pv.01 --grow --ondrive=$disk1" >> $file
echo >> $file
echo '# volume group ### ### ###' >> $file
echo "volgroup vg_$disk1 pv.01" >> $file
if [ "$disk1" != "$disk2" ] ; then
  echo "part pv.02 --grow --ondrive=$disk2" >> $file
  echo "volgroup vg_$disk2 pv.02" >> $file
  echo "logvol none --vgname=vg_$disk2 --name=lv_$disk2 --thinpool --size=1000 --grow" >> $file
fi
# echo "logvol swap --$([ ! $disk1 == 'vda' ] && echo 'hibernation' || echo 'recommended') --vgname=vg_$disk1 --name=lv_swap --fstype=swap --size=512" >> $file
echo >> $file
echo '# swap ### ### ###' >> $file
echo "logvol swap --recommended --vgname=vg_$disk1 --name=lv_swap --fstype=swap" >> $file
echo >> $file
echo '# pool ### ### ###' >> $file
echo "logvol none --vgname=vg_$disk1 --name=lv_$disk1 --thinpool --size=1000 --grow" >> $file
echo >> $file
echo '# root ### ### ###' >> $file
echo "logvol / --vgname=vg_$disk2 --name=lv_root --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,dir_nlink,resize_inode -I 256 -i 24576\" --fsoptions=\"rw,noatime,suid,dev,exec,auto,nouser,async\" --size=8000 --thin --poolname=lv_$disk2" >> $file
echo >> $file
echo '# home ### ### ###' >> $file
echo "logvol /home --vgname=vg_$disk1 --name=lv_home --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 256 -i 24576\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --size=2000 --thin --poolname=lv_$disk1" >> $file
echo >> $file
echo '# var ### ### ###' >> $file
echo "logvol /var --vgname=vg_$disk1 --name=lv_var --fstype=ext4 --mkfsoptions=\"-O none,extent,extra_isize,ext_attr,dir_index,filetype,sparse_super,flex_bg,uninit_bg,large_file,has_journal,dir_nlink,resize_inode -I 256 -i 24576\" --fsoptions=\"rw,relatime,lazytime,suid,dev,exec,auto,nouser,async\" --size=2000 --thin --poolname=lv_$disk1" >> $file

# echo >> $file
# echo "# packages based on block device" >> $file
# echo "%packages" >> $file
# echo "$([ $disk2 != 'vda' ] && echo '-')qemu-guest-agent" >> $file
# echo "%end" >> $file

[ -z ${1+x} ] || ( [ ${1} = 'test' ] && cat ${file} )
