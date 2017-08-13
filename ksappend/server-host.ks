# ksappend/server-host.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/ksappend/basic.ks

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/server/core.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/server/container-management.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/server/headless-management.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/server/virtualization-headless.ks
