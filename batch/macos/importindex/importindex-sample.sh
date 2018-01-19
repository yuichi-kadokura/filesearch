#!/bin/sh

echo "Run makeindex-sample.sh first and place the json file in the /var/tmp/filesearch directory."
./importindex.sh -e http://localhost:9200/filesearch -i /var/tmp/filesearch -d 0 -c 1

