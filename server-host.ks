# base/server-host.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

%ksappend https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/base/core.ks
%ksappend https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/base/standard.ks

%ksappend https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/server/core.ks
%ksappend https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/server/container-management.ks
%ksappend https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/server/headless-management.ks
%ksappend https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f25-dev/server/virtualization-headless.ks
