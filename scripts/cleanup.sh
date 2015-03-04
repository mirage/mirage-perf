#!/usr/bin/env bash

echo -e "${INF} cleaning up"

$XENSERVER "xe vm-shutdown --force uuid=\$(cat ./VM)"
$XENSERVER "xe vm-destroy --force uuid=\$(cat ./VM)"

$XENSERVER 'rm -rf /boot/guest'
