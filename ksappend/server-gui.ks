# ksappend/server-gui.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

xconfig --startxonboot

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/ksappend/server-host.ks

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/gui/x-base.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/gui/admin-tool.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/gui/xfce/desktop.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/gui/xfce/extra-plugins.ks

%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/server/gui/virtualization.ks
