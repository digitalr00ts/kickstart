# ksappend/basic.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

#%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/repos/rpmfusion.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/base/core.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/base/standard.ks

%packages
vim
%end
