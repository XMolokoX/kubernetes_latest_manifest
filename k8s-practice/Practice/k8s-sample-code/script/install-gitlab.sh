#install manual
apt-get install openssh-server postfix -y
wget --content-disposition https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/xenial/gitlab-ce_10.5.7-ce.0_amd64.deb/download.deb
dpkg -i gitlab-ce_10.5.7-ce.0_amd64.deb 
nano /etc/gitlab/gitlab.rb
## GitLab URL
##! URL on which GitLab will be reachable.
##! For more details on configuring external_url see:
##! https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab
external_url ' http://www.linuxhelp1.com'
gitlab-ctl reconfigure

#########install with docker
#install some tools needed
yum update -y
yum -y install git wget telnet mc java-1.8.0-openjdk-devel unzip dos2unix 

#create folder data
mkdir -p /home/gitlab/data /home/gitlab/log /home/gitlab/config

## Intsall Docker
service docker status || { \
							    yum -y install yum-utils device-mapper-persistent-data lvm2 ; \
                  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo; \
                  yum -y install docker-ce docker-ce-cli containerd.io; \
                  systemctl enable docker; \
                  systemctl start docker; \
}
sleep 5

#create container gitlab
docker run -d --hostname gitlab.example.com --name gitlab -p 80:80 -p 443:433 -v /home/gitlab/data:/var/opt/gitlab -v /home/gitlab/config:/etc/gitlab -v /home/gitlab/log:/var/log/gitlab --restart always gitlab/gitlab-ee:latest

sleep 20

#show password
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password

#install htpasswd
yum install -y httpd-tools

#set credentials
mkdir /home/auth && cd /home/auth
htpasswd -Bc registry.password user1 test

#create container docker registry
docker run -d --name registry -p 5000:5000 -v /home/auth:/auth -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/registry.password registry
