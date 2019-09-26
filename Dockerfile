FROM oraclelinux:8-slim AS stage

WORKDIR /opt

RUN yum install -y java-11-openjdk-headless maven git

RUN git clone git://git.apache.org/james-project.git

WORKDIR /opt/james-project

RUN mvn package -DskipTests -am -pl server/container/guice/cassandra-guice