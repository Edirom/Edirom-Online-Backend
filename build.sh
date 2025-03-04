#!/bin/sh

# clean build directory
ant clean

# get TEI Stylesheets
ant download-tei

# build the backend
ant build-plus

# build xar
ant xar