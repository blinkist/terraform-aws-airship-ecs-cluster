#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -Eeuxo pipefail

echo ECS_CLUSTER=${name} >> /etc/ecs/ecs.config

if [ "${block_metadata_service}" == "1" ]; then
 echo 'while ! iptables -L DOCKER-USER > /dev/null 2>/dev/null ; do echo "Waiting for the iptables DOCKER-USER chain to exist";sleep 1;done' >> /etc/rc.local
 echo iptables --insert DOCKER-USER 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP >> /etc/rc.local
fi

# EFS MOUNTING
if [ "${efs_enabled}" == "1" ]; then
  mkdir -p ${efs_mount_folder}
  if ! rpm -qa | grep -qw nfs-utils; then
    yum -y install nfs-utils
  fi

  AZ_ZONE=$(curl -L http://169.254.169.254/latest/meta-data/placement/availability-zone);
  DIR_SRC=$AZ_ZONE.${efs_id}.efs.${region}.amazonaws.com
  DIR_TGT=${efs_mount_folder}

  mount -t nfs4 $DIR_SRC:/ $DIR_TGT
  cp -p /etc/fstab /etc/fstab.back-$(date +%F)
  #Append line to fstab
  echo -e "$DIR_SRC:/ \t\t $DIR_TGT \t\t nfs \t\t defaults \t\t 0 \t\t 0" | tee -a /etc/fstab
fi

${custom_userdata}