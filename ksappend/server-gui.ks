# ksappend/server-gui.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/ksappend/x-basic.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/gui/xfce/desktop.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/gui/xfce/extra-plugins.ks

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/ksappend/server-host.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26-dev/server/gui/virtualization.ks

