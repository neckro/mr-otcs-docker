#!/bin/bash

cd /app

/usr/local/nginx/sbin/nginx &

python3 main.py &

wait -n

exit $?
