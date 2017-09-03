# ksappend/server-host.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/ksappend/basic.ks

%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/server/core.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/server/container-management.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/server/headless-management.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/server/virtualization-headless.ks
