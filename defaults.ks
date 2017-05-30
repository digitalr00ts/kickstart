# defaults.ks

install
text
cdrom
sshpw --username admin --iscrypted $6$rounds=123456$kickstart$8BDRblt8lkOOA..4iCG/xJZR6L4nl2ZJxsZ9pkoK1ECbfqkZs60Gew6j2jvVCYSi9.e.hYGK2.S1v4ZG6zpBT/

timezone America/Los_Angeles --isUtc --ntpservers=0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org

keyboard 'us'
lang en_USi.UTF-8

selinux --permissive
