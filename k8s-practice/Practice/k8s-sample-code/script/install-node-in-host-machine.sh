jenkinsAgent="host" # Consistent with pipeline/env.groovy
jenkinsUrl="http://localhost:8080/jenkins" # Jenkins URL should be with HTTP (non-HTTPS)
tmpUser="admin"
tmpPassword="admin" # Generate a random password with 14 charaters.

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