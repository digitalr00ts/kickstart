#!/bin/sh
[ -z ${desktop+x} ] && desktop=0
[ -z ${hyperv+x} ] && hyperv=0
[ -z ${qemu+x} ] && qemu=0
[ -z ${spice+x} ] && spice=0
[ -z ${vmware+x} ] && vmware=0
[ -z ${runpath+x} ] && runpath='/run/install'
file=${runpath}/vm-guests.ks

opts=$(getopt --options dhqv --long desktop,hyperv,qemu,vmware --name 'vm-guests.sh' -- "$@")
eval set -- "$opts"

while true; do
  case "$1" in
    -d|--desktop) desktop=1 ; shift ;;
    -q|--qemu) qemu=1 ; shift ;;
    -v|--vmware) vmware=1 ; shift ;;
    --) shift; break ;;
    *) echo "Invaild option: $1"; exit 1 ;;
  esac
done

echo "Virtual machine guest agents" >> $file

echo "%packages" >> $file
[ ! $vmware -eq 1 ] && echo -n '-' >> $file ; echo 'open-vm-tools' >> $file
[ ! $qemu -eq 1 ] && echo -n '-' >> $file ; echo 'qemu-guest-agent' >> $file
if [ $desktop = 1 ] ; then
  [ ! $hyperv -eq 1 ] && echo -n '-' >> $file ; echo 'hyperv-daemons' >> $file
  [ ! $vmware -eq 1 ] && echo -n '-' >> $file ; echo 'open-vm-tools-desktop' >> $file
  [ ! $qemu -eq 1 ] && echo -n '-' >> $file ; echo 'spice-vdagent' >> $file
fi
echo "%end" >> $file
