#####################################
# Multi-stage Dockerfile
# 1. Set up the build environment
# 2. Build Edirom-Online packages
# 3. Run the eXist-db and deploy XARs
#####################################


#########################
# 1. Build Environment
#########################

FROM eclipse-temurin:21 as builder

ARG ANT_VERSION=1.10.12
ARG EDITION


# Install wget and unzip and ruby and other dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        sudo \
        wget \
        unzip \
		libfreetype6 \
		fontconfig \
	&& rm -rf /var/lib/apt/lists/*

# Download and extract Apache Ant to opt folder
RUN wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz && \
    wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz.sha512 && \
    echo "$(cat apache-ant-${ANT_VERSION}-bin.tar.gz.sha512) apache-ant-${ANT_VERSION}-bin.tar.gz" | sha512sum -c && \
    tar -zvxf apache-ant-${ANT_VERSION}-bin.tar.gz -C /opt/ && \
    ln -s /opt/apache-ant-${ANT_VERSION} /opt/ant && \
    unlink apache-ant-${ANT_VERSION}-bin.tar.gz && \
    unlink apache-ant-${ANT_VERSION}-bin.tar.gz.sha512

# Put ant in the path
ENV PATH="/opt/ant/bin:${PATH}"


###########################
# 2. Edirom-Online Backend
###########################

WORKDIR /opt/eo-backend
COPY . /opt/eo-backend/
RUN ant


#########################
# 3. Run/deploy eXist-db
#########################

FROM stadlerpeter/existdb:6
ENV EXIST_PASSWORD=changeme

# copy built XARs to autodeploy directory of exist
COPY --from=builder /opt/eo-backend/build-xar/*.xar ${EXIST_HOME}/autodeploy/