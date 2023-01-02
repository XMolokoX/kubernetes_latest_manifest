FROM adoptopenjdk/openjdk8-openj9

MAINTAINER vhoang6@dxc.com

COPY . /home/jar/

WORKDIR /home/jar/

CMD java -Djdk.tls.rejectClientInitiatedRenegotiation=true -Xms128m -Xmx512m -jar infra-api-manager.jar --spring.config.name=application,bootstrap --spring.config.location=/home/config/
