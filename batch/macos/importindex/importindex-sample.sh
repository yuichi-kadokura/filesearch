#!/bin/bash

echo "Run makeindex-sample.sh first and place the json file in the ${HOME}/temp directory."
./importindex.sh -e http://localhost:9200/filesearch -i ~/temp -d 0 -c 1

