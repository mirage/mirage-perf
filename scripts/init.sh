#!/usr/bin/env bash
#
# Copyright (C) 2015 University of Nottingham <masoud.koleini@nottingham.ac.uk>
#
# Permission to use, copy, modify, and distribute this software for any purpose
# with or without fee is hereby granted, provided that the above copyright
# notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

ERR='\033[0;31m[ERROR]\033[0m'
WRN='\033[1;33m[WARNING]\033[0m'
INF='\033[1;34m[INFO]\033[0m'

sudo add-apt-repository -y ppa:avsm/ppa
sudo apt-get update
sudo apt-get -yf build-essential m4 install openssh-client sshpass libssl-dev
sudo apt-get -yf ocaml ocaml-native-compilers camlp4-extra opam

PACKAGES="mirage tcpip"
opam init -y
eval `opam config env`
opam install $PACKAGES -y
