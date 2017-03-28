#cloud-config
rancher:
write_files:
  - path: /etc/rc.local
    permissions: "0755"
    owner: root
    content: |
      #!/bin/bash
      wait-for-docker
      IP=`ip addr show dev eth0|grep -w 'inet'|awk '{print $2}'|cut -d '/' -f1`
      docker run -d --restart=unless-stopped -p 8080:8080 -p 9345:9345 rancher/server  --db-host ${endpoint} --db-port ${port} --db-user ${username} --db-pass ${password} --db-name ${dbname} --advertise-address $${IP}