#!/bin/bash

IPADDR=$(curl ifconfig.me)

jenkinsAgent="host" # Consistent with pipeline/env.groovy
jenkinsUrl="http://localhost:8080/jenkins" # Jenkins URL should be with HTTP (non-HTTPS)
tmpUser="jenkins"
tmpPassword="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 14 ; echo '')"

# Github Pipeline
pipelineGitUrl="http://$IPADDR/root/lab1.git"
pipelineGitBranch="main"
pipelineFolder="pipeline"

# Maven
mvnName="MAVEN" # Consistent with pipeline/env.groovy
mvnVersion="3.6.2" #The latest version: 3.6.3

# Credential With Git Token
credentialsId="minhquan010710" # Consistent with pipeline/env.groovy
credentialDescription="for Git" #Description
credentialUser="root"  #user
credentialToken="P@ssword123" #token

#Credential with docker id
credentialsdocker="docker_id" # Consistent with pipeline/env.groovy
credentialDockerDescription="For Registry" #Description
credentialDockerUser=""  #user
credentialDockerToken="" #token


#update
apt update -y

#install some tools needed
apt -y install git wget telnet default-jre 

#java verision
java -version

sleep 5

#create docker home
mkdir -p /home/jenkins/data && chmod 777 /home/jenkins /home/jenkins/data

## Intsall Docker
service docker status || { \
							    apt install -y apt-transport-https ca-certificates curl software-properties-common; \
                  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; \
                  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"; \
                  apt update -y; \
                  apt install -y docker-ce; \
                  systemctl enable docker; \
                  systemctl start docker; \
}
sleep 10

#create container gitlab
docker run -d --hostname gitlab.example.com --name gitlab -p 80:80 -p 443:433 -v /home/gitlab/data:/var/opt/gitlab -v /home/gitlab/config:/etc/gitlab -v /home/gitlab/log:/var/log/gitlab --restart always gitlab/gitlab-ee:latest

sleep 10


#create docker image
cat <<EOL > $(echo /home/jenkins/plugins)
ace-editor
antisamy-markup-formatter
apache-httpcomponents-client-4-api
authentication-tokens
bouncycastle-api
branch-api
build-timeout
cloudbees-folder
command-launcher
credentials
credentials-binding
display-url-api
durable-task
email-ext
emailext-template
ghprb
git
git-client
git-server
github
github-api
github-branch-source
gradle
handlebars
jackson2-api
jdk-tool
jquery-detached
jsch
junit
ldap
lockable-resources
mailer
mapdb-api
matrix-auth
matrix-project
momentjs
pam-auth
Parameterized-Remote-Trigger
pipeline-build-step
pipeline-github-lib
pipeline-graph-analysis
pipeline-input-step
pipeline-milestone-step
pipeline-model-api
pipeline-model-definition
pipeline-model-extensions
pipeline-rest-api
pipeline-stage-step
pipeline-stage-tags-metadata
pipeline-stage-view
plain-credentials
resource-disposer
scm-api
script-security
ssh-credentials
ssh-slaves
structs
subversion
timestamper
token-macro
trilead-api
versionnumber
workflow-aggregator
workflow-api
workflow-basic-steps
workflow-cps
workflow-cps-global-lib
workflow-durable-task-step
workflow-job
workflow-multibranch
workflow-scm-step
workflow-step-api
workflow-support
ws-cleanup
github-pr-comment-build
github-pr-coverage-status
github-pullrequest
fitnesse
sonar
EOL

cat <<EOL > $(echo /home/jenkins/security.groovy)
#!groovy

import jenkins.model.*
import jenkins.security.s2m.AdminWhitelistRule

import hudson.security.*
import hudson.tools.*
import hudson.tasks.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${tmpUser}", "${tmpPassword}")
instance.setSecurityRealm(hudsonRealm)

//Anyone can do anything
def strategy = new AuthorizationStrategy.Unsecured()
instance.setAuthorizationStrategy(strategy)

//Grants full-control to authenticated user and optionally read access to anonymous users
//def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
//instance.setAuthorizationStrategy(strategy)

// Disable CSRF Protection
//instance.setCrumbIssuer(null)

instance.save()
Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// Add a Maven Installation Tool to Global Tool Configuration
mavenPlugin = Jenkins.instance.getExtensionList(hudson.tasks.Maven.DescriptorImpl.class)[0]
newMavenInstall = new hudson.tasks.Maven.MavenInstallation("${mvnName}", null, [new hudson.tools.InstallSourceProperty([new hudson.tasks.Maven.MavenInstaller("${mvnVersion}")])])
mavenPlugin.installations += newMavenInstall
mavenPlugin.save()
EOL

cat <<EOL > $(echo /home/jenkins/Dockerfile)
FROM jenkins/jenkins
COPY plugins /tmp/plugins
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy
RUN /usr/local/bin/install-plugins.sh < /tmp/plugins
EOL

cd /home/jenkins && docker build -t jenkins . 

docker run --name jenkins -d -p 8080:8080 -p 50000:50000 -e JENKINS_OPTS="--prefix=/jenkins"  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" -v /home/jenkins/data:/var/jenkins_home jenkins

sleep 50

## Run Jenkins Agent
mkdir -p /tmp/jenkins /home/apps/jenkins/agent
wget "${jenkinsUrl}/jnlpJars/jenkins-cli.jar" -O /tmp/jenkins/jenkins-cli.jar

### Generate the configuration for Jenkins Agent
cat <<EOL > /tmp/jenkins/config.xml
<slave>
  <remoteFS>/home/apps/jenkins/agent</remoteFS>
  <numExecutors>3</numExecutors>
  <mode>EXCLUSIVE</mode>
  <launcher class="hudson.slaves.JNLPLauncher" />
</slave>
EOL

### Create new node Jenkins Agent
cat /tmp/jenkins/config.xml | java -jar /tmp/jenkins/jenkins-cli.jar -s ${jenkinsUrl} -auth ${tmpUser}:${tmpPassword} create-node ${jenkinsAgent}

### Connect Agent to Master Jenkins
#### Get Jenkins secret
curl -u ${tmpUser}:${tmpPassword} -o /tmp/jenkins/slave-agent.jnlp ${jenkinsUrl}/computer/${jenkinsAgent}/slave-agent.jnlp
jenkinsSecret=$(grep -E -o "[a-z0-9]{64}" /tmp/jenkins/slave-agent.jnlp)

#### Generate script Jenkins Agent start
wget ${jenkinsUrl}/jnlpJars/agent.jar -O /home/apps/jenkins/agent/agent.jar
cat <<EOL > $(echo /home/apps/jenkins/agent/jenkinsAgent.sh)
nohup java -jar /home/apps/jenkins/agent/agent.jar -jnlpUrl ${jenkinsUrl}/computer/${jenkinsAgent}/slave-agent.jnlp -secret ${jenkinsSecret} -workDir "/home/apps/jenkins/agent" &
EOL
sh /home/apps/jenkins/agent/jenkinsAgent.sh > /dev/null 2>&1
##### Add crontab auto start Jenkins Agent after rebooting.
echo "@reboot sh /home/apps/jenkins/agent/jenkinsAgent.sh > /dev/null 2>&1" >> /var/spool/cron/root

## Create a CredentialsId to Clone Github Code
cat <<EOL > /tmp/jenkins/credential.xml
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.3.12">
  <scope>GLOBAL</scope>
  <id>${credentialsId}</id>
  <description>${credentialDescription}</description>
  <username>${credentialUser}</username>
  <password>${credentialToken}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOL
cat /tmp/jenkins/credential.xml | java -jar /tmp/jenkins/jenkins-cli.jar -s ${jenkinsUrl} -auth ${tmpUser}:${tmpPassword} create-credentials-by-xml  system::system::jenkins _
rm -rf /tmp/jenkins/credential.xml

## Create a CredentialsId to Push Image
cat <<EOL > /tmp/jenkins/credential.xml
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.3.12">
  <scope>GLOBAL</scope>
  <id>${credentialsdocker}</id>
  <description>${credentialDockerDescription}</description>
  <username>${credentialDockerUser}</username>
  <password>${credentialDockerToken}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOL
cat /tmp/jenkins/credential.xml | java -jar /tmp/jenkins/jenkins-cli.jar -s ${jenkinsUrl} -auth ${tmpUser}:${tmpPassword} create-credentials-by-xml  system::system::jenkins _

## Import and Run "init-env"
jobName="lab1"
filepipeline="cicd"
cat <<EOL > /tmp/jenkins/job.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.39">
  <keepDependencies>false</keepDependencies>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.81">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.3.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${pipelineGitUrl}</url>
          <credentialsId>${credentialsId}</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${pipelineGitBranch}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
    </scm>
    <scriptPath>${pipelineFolder}/${filepipeline}.groovy</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <disabled>false</disabled>
</flow-definition>
EOL

### Import job
cat /tmp/jenkins/job.xml | java -jar /tmp/jenkins/jenkins-cli.jar -s ${jenkinsUrl} -auth ${tmpUser}:${tmpPassword} create-job ${jobName}

### Create a new Jenkins user
jenkinsUser="admin"
jenkinsPass="admin"
eval $(echo 'echo '\''jenkins.model.Jenkins.instance.securityRealm.createAccount("'${jenkinsUser}'", "'${jenkinsPass}'")'\'' | java -jar /tmp/jenkins/jenkins-cli.jar -s '${jenkinsUrl}' -auth '${tmpUser}':'${tmpPassword}' groovy =')

### Remove tmpUser
eval $(echo 'echo '\''hudson.model.User.get("'${tmpUser}'").delete()'\'' | java -jar /tmp/jenkins/jenkins-cli.jar -s '${jenkinsUrl}' -auth '${jenkinsUser}':'${jenkinsPass}' groovy =')

## Clean tmp
rm -rf /tmp/jenkins/

#install azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#check version
az version

#install kubectl for cluster
az aks install-cli

#login in az cli
#az login --service-principal -u bc7fef5f-b3b5-4b7d-8673-de2ba07ebdcf -p rzj8Q~5c5sNnvUyp7ugsPwQZ5OFCkm6hbuu6cc2J --tenant 4da74a5d-25ba-4e70-b339-714519255351
az login

#create acr 
az acr create --resource-group k8slab1 --name lab1k8s --sku Basic

#create k8s cluster
az aks create --resource-group k8slab1 --name k8sCluster --node-count 2 --node-vm-size 'standard_a2_v2' --generate-ssh-keys --attach-acr lab1k8s

#configure kubectl for cluster
az aks get-credentials --resource-group k8slab1 --name k8sCluster

#install helm
cd /home/apps && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

clear
#check node
kubectl get nodes
echo '========================================================================FINISH========================================================================'
echo "1. Access Jenkins : http://IP:8080/jenkins/"
echo "2. We should change \"Anyone can do anything\" to \"Logged-in users can do anything\" in \"Configure Global Security\""
echo $(docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password)
echo '========================================================================FINISH========================================================================'



