FROM tomcat:9-jre11
WORKDIR /usr/local/tomcat

# xmlstarlet, jq, lz4
RUN  apt-get update \
  && apt-get install -y --no-install-recommends xmlstarlet jq liblz4-tool \
  && rm -r /var/lib/apt/lists/*

# SOLR 3
RUN  mkdir solr \
  && mkdir solr/lib \
  && mkdir solr/lib/solrj-lib \
  && mkdir solr/shared-lib \
  && mkdir solr/conf \
  && mkdir solr/data \
  && curl -JL https://archive.apache.org/dist/lucene/solr/3.6.2/apache-solr-3.6.2.tgz | tar xz -C /tmp \
  && cp /tmp/apache-solr-3.6.2/dist/apache-solr-3.6.2.war webapps/solr.war \
  && cp -r /tmp/apache-solr-3.6.2/example/solr/conf/* solr/conf/ \
  && cp /tmp/apache-solr-3.6.2/dist/*.jar solr/lib/ \
  && cp /tmp/apache-solr-3.6.2/dist/apache-solr-dataimporthandler-*.jar solr/shared-lib/ \
  && cp /tmp/apache-solr-3.6.2/dist/solrj-lib/*.jar solr/lib/solrj-lib/ \
  && rm -r /tmp/apache-solr-3.6.2

# SOLR Plugins: commons-lang3, mongo-java-driver, mongo-importer, mysql-connector
WORKDIR solr/lib
RUN curl -OJL "https://search.maven.org/remotecontent?filepath=org/apache/commons/commons-lang3/3.6/commons-lang3-3.6.jar"
RUN curl -OJL "https://search.maven.org/remotecontent?filepath=org/mongodb/mongo-java-driver/3.3.0/mongo-java-driver-3.3.0.jar"
RUN curl -OJL "https://github.com/BuyerQuest/SolrMongoImporter/releases/download/v1.2.0/solr-mongo-importer-1.2.0.jar"
RUN curl -OJL "https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.34/mysql-connector-java-5.1.34.jar"

WORKDIR /usr/local/tomcat
# Logger configuration
COPY ./artifacts/log4j.properties conf/
# bootstrapper that creates our solr cores
COPY ./artifacts/run-tomcat-and-create-cores.sh bin/
# Container-init script
COPY ./artifacts/container-init.sh bin/

# For customization, set EXTRA_CATALINA_OPTS
ENV SOLR_XMS 128m
ENV SOLR_XMX 1024m
ENV CATALINA_OPTS -Xms${SOLR_XMS} -Xmx${SOLR_XMX} -Dlog4j.configuration=file:/usr/local/tomcat/conf/log4j.properties -Dsolr.allow.unsafe.resourceloading=true $EXTRA_CATALINA_OPTS

# This is a PCRE regex that the container's catalina.out tail is filtered against. Keeps healthcheck spam out of your docker log
ENV STDOUT_FILTER '^\d{2}-[a-zA-Z]{3}-\d{4,} (\d{2}(:|.)+){3}\d{3} INFO \[http-nio-([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])-exec-\d+\] org\.apache\.solr\.core\.SolrCore\.execute \[\] webapp=\/solr path=\/admin\/ping params={wt=json&docker-healthcheck=true}( hits=0)? status=0 QTime=\d+\s*$'

# Create an easy-to-use path for core data and symlink it
RUN  mkdir /cores \
  && ln -s /cores solr/cores \
  && mkdir /core-init /container-init
VOLUME ["/cores"]

HEALTHCHECK --interval=5s --start-period=15s \
  CMD test "$(curl --fail --silent 'http://localhost:8080/solr/admin/ping?wt=json&docker-healthcheck=true' | jq -r '.status')" = "OK"

EXPOSE 8080
CMD ["run-tomcat-and-create-cores.sh"]
