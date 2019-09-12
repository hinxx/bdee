#!/bin/bash
#

set -x

packages_dir=$(realpath $(dirname $0)/../packages)
packages_files=$(find $packages_dir -name *.pkg)