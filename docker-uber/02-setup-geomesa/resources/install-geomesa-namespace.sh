#! /usr/bin/env bash
#
# Copyright (c) 2013-2016 Commonwealth Computer Research, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0 which
# accompanies this distribution and is available at
# http://www.opensource.org/licenses/apache2.0.php.
#

# Installs a GeoMesa distributed runtime JAR into HDFS and sets up a corresponding Accumulo namespace

while getopts ":u:p:n:g:h:d:" opt; do
  case $opt in
    u)
      ACCUMULO_USER=$OPTARG
      ;;
    p)
      ACCUMULO_PASSWORD=$OPTARG
      ;;
    n)
      ACCUMULO_NAMESPACE=$OPTARG
      ;;
    g)
      GEOMESA_JAR=$OPTARG
      ;;
    d)
      NAMESPACE_DIR=$OPTARG
      ;;
    h)
      HDFS_URI=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ACCUMULO_USER" ]]; then
    echo "Accumulo username parameter is required: -u" >&2
    ERROR=1
fi

if [[ -z "$ACCUMULO_NAMESPACE" ]]; then
    echo "Accumulo namespace parameter is required: -n" >&2
    ERROR=1
fi

if [[ -z "$GEOMESA_JAR" ]]; then
    # cd to directory of script and look for GeoMesa JAR
    cd "$( dirname "${BASH_SOURCE[0]}" )"
    GEOMESA_JAR=$(ls | grep geomesa-accumulo-distributed-runtime)
    if [ -z "$GEOMESA_JAR" ]; then
        echo "Could not find GeoMesa distributed runtime JAR - please specify the JAR using the '-g' flag"
        ERROR=1
    else
        echo "Using GeoMesa JAR: $GEOMESA_JAR"
    fi
fi

if [[ -z "$NAMESPACE_DIR" ]]; then
    NAMESPACE_DIR="/accumulo/classpath"
    echo "Using namespace directory: $NAMESPACE_DIR"
fi

if [[ -z "$HDFS_URI" ]]; then
    HDFS_URI=`hdfs getconf -confKey fs.defaultFS`
fi

if [[ $HDFS_URI == hdfs* ]]; then
    echo "Using HDFS URI: $HDFS_URI"
else
    echo "Invalid HDFS URI discovered: $HDFS_URI"
    ERROR=1
fi

if [[ -z "$ERROR" && -z "$ACCUMULO_PASSWORD" ]]; then
    read -s -p "Enter Accumulo password for user $ACCUMULO_USER: " ACCUMULO_PASSWORD
    echo
fi

if [[ -n "$ERROR" ]]; then
    echo -e "\nRequired parameters:\n\t" \
      "-u (Accumulo username)\n\t" \
      "-n (Accumulo namespace)"
    echo -e "Optional parameters:\n\t" \
      "-p (Accumulo password)\n\t" \
      "-g (Path of GeoMesa distributed runtime JAR)\n\t" \
      "-d (Directory to create namespace in, defaults to /accumulo/classpath)\n\t" \
      "-h (HDFS URI e.g. hdfs://localhost:54310)"
    exit 1
fi

echo "Copying GeoMesa JAR for Accumulo namespace $ACCUMULO_NAMESPACE..."
hadoop fs -mkdir -p "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}"
echo NAMESPACE_DIR=$NAMESPACE_DIR
echo ACCUMULO_NAMESPACE=$ACCUMULO_NAMESPACE
echo "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}" created

hadoop fs -copyFromLocal -f "$GEOMESA_JAR" "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}/"
echo copyFromLocal -f "$GEOMESA_JAR" "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}/" ok

echo check hadoop fs -ls "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}/geomesa*.jar"
if hadoop fs -ls "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}/geomesa*.jar" > /dev/null 2>&1
then
    echo "create namespace... "
    echo -e "createnamespace ${ACCUMULO_NAMESPACE}\n" \
      "grant NameSpace.CREATE_TABLE -ns ${ACCUMULO_NAMESPACE} -u $ACCUMULO_USER\n" \
      "config -s general.vfs.context.classpath.${ACCUMULO_NAMESPACE}=${HDFS_URI}${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}/.*.jar\n" \
      "config -ns ${ACCUMULO_NAMESPACE} -s table.classpath.context=${ACCUMULO_NAMESPACE}\n" \
      | accumulo shell -u $ACCUMULO_USER -p $ACCUMULO_PASSWORD

    if [[ $? -eq 1 ]]; then
        echo "Error encountered executing Accumulo shell commands, check above output for errors."
    else
        echo "Successfully installed GeoMesa distributed runtime JAR."
fi
else
  echo fs -ls "${NAMESPACE_DIR}/${ACCUMULO_NAMESPACE}/geomesa*.jar" failed
  echo "No GeoMesa JAR found in HDFS. Please check HDFS (permissions?) and try again."
fi


