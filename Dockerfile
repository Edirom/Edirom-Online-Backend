######################################
# Multi-stage Dockerfile
# 1. Set up and build environment
# 2. Run the eXist-db and deploy XARs
######################################


#########################
# 1. Build Environment
#########################

FROM eclipse-temurin:21 as builder

# installing Apache Ant
RUN apt-get install -y --no-install-recommends apt-transport-https \
    && apt-get update \
    && apt-get install -y --no-install-recommends ant curl zip unzip patch git

WORKDIR /opt/eo-backend

COPY . .

RUN ant


#########################
# 2. Run/deploy eXist-db
#########################

FROM stadlerpeter/existdb:6

# copy built XARs to autodeploy directory of exist
COPY --from=builder /opt/eo-backend/build-xar/*.xar ${EXIST_HOME}/autodeploy/