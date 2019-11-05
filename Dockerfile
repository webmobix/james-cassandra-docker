FROM openjdk:11-jdk AS build

WORKDIR /opt

RUN apt-get update \
  && apt-get install -y maven git

RUN git clone https://github.com/apache/james-project.git \
  && cd james-project \
  && git fetch --tags \
  && git checkout tags/james-project-3.4.0

WORKDIR /opt/james-project

RUN mvn package -X -DskipTests -am -pl server/container/guice/cassandra-rabbitmq-guice

FROM openjdk:11-jre

WORKDIR /opt/james

COPY --from=build /opt/james-project/server/container/guice/cassandra-rabbitmq-guice/target/james-server-cassandra-rabbitmq-guice.jar james-server-cassandra-rabbitmq-guice.jar
COPY --from=build /opt/james-project/server/container/guice/cassandra-rabbitmq-guice/target/james-server-cassandra-rabbitmq-guice.lib james-server-cassandra-rabbitmq-guice.lib
COPY --from=build /opt/james-project/dockerfiles/run/guice/cassandra/destination/conf conf

RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /usr/bin/dumb-init

RUN groupadd -g 1001 james && useradd -d /opt/james -s /bin/bash -g james -G mail -u 1001 james

RUN mkdir -p /opt/james/var/mail && chown -R james:james /opt/james/var/mail

USER 1001

VOLUME [ "/opt/james/conf", "/var/mail" ]

EXPOSE 3110 3995 3143 3993 3025 3465 8000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["java", "-Dworking.directory=/opt/james", "-Dlogback.configurationFile=/opt/james/conf/logback.xml", "-Xmx1024m", "-jar", "james-server-cassandra-rabbitmq-guice.jar"]
