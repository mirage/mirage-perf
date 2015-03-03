#!/bin/bash

ERR='\033[0;31m[ERROR]\033[0m'
WRN='\033[1;33m[WARNING]\033[0m'
INF='\033[1;34m[INFO]\033[0m'

TMP=/tmp

sudo apt-get install -y openssh-client sshpass libssl-dev

# install opam and all dependencies
opam install -y xe-unikernel-upload mirage


