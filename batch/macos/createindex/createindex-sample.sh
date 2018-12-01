#!/bin/bash

echo "Make a ${HOME}/temp directory before running."
./createindex-dir.sh -t /usr/share/doc -o ~/temp -r /usr -d smb:// -n 0

