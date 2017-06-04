# ksappend/basic.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

%include https://github.com/digitalr00ts/korora-kickstart/raw/f25-dev/repos/rpmfusion.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/base/core.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/base/standard.ks

%packages
vim
%end
