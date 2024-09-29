#MAINTAINER Puneet Joshi <puneetjoshi@cloudera.com>
# Base Image 
FROM centos:7.9.2009

# Directory for storing scripts.
RUN mkdir -p /opt/cdp-public-cloud-automation
# Setting Up Environment Variable.
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV HOME_DIR="/opt/cdp-public-cloud-automation"

# Installing Required Packages.
RUN yum -y update && \
    yum -y install epel-release && \
    yum -y install jq wget git make which unzip rust openssl11 openssl11-devel gcc openssl-devel bzip2-devel libffi-devel && \
    yum -y clean all && \
    rm -fr /var/cache && \
    wget https://www.python.org/ftp/python/3.10.9/Python-3.10.9.tgz && \    
    tar -xvf Python-3.10.9.tgz && \
    cd Python-3.10.9 && \
    sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure && \
    ./configure --enable-optimizations && \
    make altinstall && \
    cp /usr/local/bin/python3.10 /usr/bin/ && \
    rm -f /usr/bin/python && \    
    ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm /Python-3.10.9.tgz && \
    rm /Python-3.10.9/get-pip.py && \
    rm -rf /Python-3.10.9
RUN pip install --upgrade pip && \
    pip install setuptools_rust && \
    pip install ansible-core==2.12.10 && \
    pip install cdpcli && \
    pip install jmespath==1.0.1 && \
    pip install git+https://github.com/cloudera-labs/cdpy@main#egg=cdpy && \
    ansible-galaxy collection install community.general && \
    ansible-galaxy collection install git+https://github.com/cloudera-labs/cloudera.cloud.git,devel && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/Cscliv2.zip" && \
    unzip /tmp/Cscliv2.zip -d /tmp/ && \
    /tmp/aws/install && \
    curl "https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip" -o "/tmp/terraform_1.4.6_linux_amd64.zip" && \
    unzip /tmp/terraform_1.4.6_linux_amd64.zip -d /usr/local/bin/ && \
    rm -rf /tmp/Cscliv2.zip && \
    rm -rf /tmp/terraform_1.4.6_linux_amd64.zip && \
    rm -fr /var/cache    
COPY cdp-wrkshps-quickstarts /opt/cdp-public-cloud-automation/cdp-wrkshps-quickstarts
COPY entrypoint/docker-entrypoint.sh /usr/local/bin/
COPY entrypoint/hol-functions.sh /usr/local/bin/
COPY entrypoint/default.py /usr/local/lib/python3.10/site-packages/ansible/plugins/callback/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
WORKDIR "$HOME_DIR"
#CMD ["/bin/bash"]
ENTRYPOINT ["docker-entrypoint.sh"]