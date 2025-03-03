#!/bin/sh

# clean build directory
ant clean

# get additional stuff for exist-db
ant build-plus

# build xar
ant xar