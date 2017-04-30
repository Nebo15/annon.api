#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export MAX_HEAP_SIZE=128M
export HEAP_NEWSIZE=24M
java -version
wget http://www.us.apache.org/dist/cassandra/3.10/apache-cassandra-3.10-bin.tar.gz
tar -xzf apache-cassandra-3.10-bin.tar.gz
sh ./apache-cassandra-3.10/bin/cassandra 2>&1 >/dev/null
