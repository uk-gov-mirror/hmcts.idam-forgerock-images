FROM centos:7.5.1804

ENV container docker

# Update and install java and tools
RUN yum -y update && yum -y install java-1.8.0-openjdk-headless wget sudo systemd; yum clean all

# Get Tomcat and put it in a directory Ansible can use
RUN mkdir -p /usr/tmp
RUN wget -nv https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.42/bin/apache-tomcat-8.5.42.tar.gz -O /usr/tmp/apache-tomcat-8.5.42.tar.gz

# Workaround for systemd not working in centos
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]