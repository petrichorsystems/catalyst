#!/bin/bash

source /tmp/chroot-functions.sh

## START BUILD
setup_pkgmgr

run_merge "-e --update --deep --with-bdeps=y @system"
