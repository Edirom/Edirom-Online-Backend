#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM openjdk:8-jdk as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends ant 

WORKDIR /opt/app

COPY . .

RUN ant

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb:4

COPY --chown=wegajetty --from=builder /opt/app/build/*.xar ${EXIST_HOME}/autodeploy/
