# ksappend/xfce.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

xconfig --startxonboot

%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/repos/rpmfusion.ks

%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/ksappend/x-basic.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/ksappend/_x-apps.ks

%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/gui/xfce/apps.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/gui/xfce/desktop.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/gui/xfce/extra-plugins.ks
%include https://raw.githubusercontent.com/digitalr00ts/kickstart/f26/gui/xfce/media.ks
