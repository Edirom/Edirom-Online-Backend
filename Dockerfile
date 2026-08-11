######################################
# Multi-stage Dockerfile
# 1. Set up and build environment
# 2. Run the eXist-db and deploy XARs
######################################


#########################
# 1. Build Environment
#########################

FROM eclipse-temurin:21 AS builder

ARG ROASTER_VERSION=1.11.0

# installing Apache Ant
RUN apt-get install -y --no-install-recommends apt-transport-https \
    && apt-get update \
    && apt-get install -y --no-install-recommends ant curl zip unzip patch git

WORKDIR /opt/eo-backend

COPY . .

RUN ant

RUN echo "Downloading dependencies..." && \
    mkdir -p /opt/roaster && \
    cd /opt/roaster && \
    curl -L -O "https://exist-db.org/exist/apps/public-repo/public/roaster-${ROASTER_VERSION}.xar";


#########################
# 2. Run/deploy eXist-db
#########################

FROM stadlerpeter/existdb:6
ENV EXIST_PASSWORD=changeme

# copy built XARs to autodeploy directory of exist
COPY --from=builder /opt/eo-backend/build-xar/*.xar ${EXIST_HOME}/autodeploy/
COPY --from=builder /opt/roaster/*.xar ${EXIST_HOME}/autodeploy/