#!/bin/bash
port=3000
if [ -n "$1" ]; then port=$1; fi
cd .. &  thin start -R config.ru -p ${port} -a 127.0.0.1 -e enviroment.rb
