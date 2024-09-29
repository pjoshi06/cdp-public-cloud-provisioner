#!/bin/bash
sudo su - root
yum -y update
yum -y install epel-release
yum -y install ansible
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
systemctl start docker
systemctl enable docker
docker run -d -p 80:8080 --name=keycloak -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=Cloudera123 keycloak/keycloak start-dev >> /tmp/kc_init.log
sleep 40
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password Cloudera123 >> /tmp/kc_init.log
sleep 5
docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE --server http://localhost:8080 --realm master --user admin --password Cloudera123 >> /tmp/kc_init.log
#docker restart keycloak
#sleep 10
#docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE --server http://localhost:8080 --realm master --user admin --password Cloudera123
#docker cp /tmp/cloudera-wshps.png keycloak:/opt/jboss/keycloak/themes/keycloak/login/resources/img/keycloak-bg.png
#docker cp /tmp/cloudera-newco-wshps.png keycloak:/opt/jboss/keycloak/themes/keycloak/login/resources/img/keycloak-logo-text.png

