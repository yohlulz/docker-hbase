FROM ubuntu

ENV HBASE_VER=1.1.3

############################### System reqs
# install requirements
ENV DEBIAN_FRONTEND noninteractive
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN \
  apt-get update && \
  apt-get install -y python-setuptools \
                        python-software-properties \
                        software-properties-common \
                        curl \
                        nano \
                        vim \
                        htop \
                        tar \
                        ant \
			ssh \
			liblzo2-dev \
			make \
			supervisor \
			git

# install java
RUN \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java7-installer

# make link to JAVA_HOME set in hbase-env.sh
RUN mkdir /usr/java && ln -s /usr/lib/jvm/java-7-oracle /usr/java/jdk1.7
ENV JAVA_HOME=/usr/java/jdk1.7

# For nano to work properly
ENV TERM=xterm
############################################

############################# Hbase specific
# Switch to root user
USER root

# Install hbase
RUN curl -fLs http://apache.org/dist/hbase/${HBASE_VER}/hbase-${HBASE_VER}-bin.tar.gz | tar xzf - -C /opt && mv /opt/hbase-${HBASE_VER} /opt/hbase

# Add HBASE to path
ENV PATH=/opt/hbase/bin:$PATH
ENV HBASE_HOME=/opt/hbase
###########################################

############################ Modify configs
ADD etc/conf/* /opt/hbase/conf/
ADD etc/bin/* /opt/hbase/bin/
ADD etc/create_table.sh /opt/hbase/bin/create_tsd_tables.sh
RUN sed -i 's/ssh.*/eval ${cmd}/g' /opt/hbase/bin/zookeepers.sh && \
    sed -i 's/true/never/g' /opt/hbase/bin/stop-hbase.sh && \
    sed -i 's/-f ${HBASE_PID}/0 == 1/g' /opt/hbase/bin/hbase-daemon.sh

ADD etc/supervisord.conf /etc/supervisord.conf
ADD etc/supervisord.d/* /etc/supervisord.d/
##########################################

################################ LZO
RUN git clone git://github.com/cloudera/hadoop-lzo.git /tmp/lzo && \
		sed -i 's|<class name="com.hadoop.compression.lzo.LzoDecompressor" />|<class name="com.hadoop.compression.lzo.LzoDecompressor" /> <classpath refid="classpath"/>|g' /tmp/lzo/build.xml && \
		mkdir -p /opt/hbase/lib/native && \
		cd /tmp/lzo/; ant clean compile jar tar && \
		cp /tmp/lzo/build/hadoop-lzo*/hadoop-lzo*.jar /opt/hbase/lib/ && \
		cp -a build/hadoop-lzo*/lib/native/* /opt/hbase/lib/native/ && \
		rm -rf /tmp/lzo
# test
RUN hbase org.apache.hadoop.hbase.util.CompressionTest /tmp/test_file lzo
########################################

############################ EXPOSE PORTS
# zookeeper
EXPOSE 2181

# hbase.master.port
EXPOSE 16000

# hbase.master.info.port (http)
EXPOSE 16010

# hbase.regionserver.port
EXPOSE 16020

# hbase.regionserver.info.port (http)
EXPOSE 16030

# hbase.rest.port
EXPOSE 8080
############################################


VOLUME ["/opt/hbase-data", "/opt/hbase/conf"]

#Start supervisor
CMD ["/opt/hbase/bin/startup.sh"]
#CMD ["/usr/bin/supervisord","-c", "/etc/supervisord.conf"]

