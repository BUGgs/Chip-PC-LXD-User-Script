echo "/bin/bash /xcalibur/deployment/scripts/config.sh &" >> /etc/init.d/startup
/bin/bash /xcalibur/deployment/scripts/config.sh
eval "/sbin/reboot"