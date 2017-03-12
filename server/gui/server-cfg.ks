# server/server-cfg.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Server Configuration Tools
# Description: This group contains all of Red Hat's custom server configuration tools.

%packages

# Default
cups-pk-helper
#system-config-httpd
system-config-nfs
system-config-samba
system-config-services

# Optional
#system-config-bind
system-config-printer
#system-switch-mail-gnome

%end

