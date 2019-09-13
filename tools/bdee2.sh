#!/bin/bash
#

# set -x

packages_config=$(realpath $(dirname $0)/../packages/packages.cfg)
recipes_config=$(realpath $(dirname $0)/../recipes/recipes.cfg)
work_path=$(pwd)

# echo GREP looking for adcore package:
# grep ^adcore $packages_config

# echo GREP looking for foo package:
# grep ^foo $packages_config

# one option line per section
# echo
# echo AWK looking for adcore package:
# p=adcore
# awk "/^$p[[:space:]]+NAME/ { print \$3; }" $packages_config

# multiple option lines per section
# echo
# echo AWK looking for busy package:
# p=busy
# awk "/^$p[[:space:]]+TAGG/ { \$1=\$2=\"\"; print \$0; }" $packages_config


function name() {
	awk "/^$1[[:space:]]+NAME/ { print \$3; }" $packages_config
}

function repo() {
	awk "/^$1[[:space:]]+REPO/ { print \$3; }" $packages_config
}

function tag() {
	awk "/^$1[[:space:]]+TAG/ { print \$3; }" $packages_config
}

function branch() {
	awk "/^$1[[:space:]]+BRANCH/ { print \$3; }" $packages_config
}

function path() {
	echo $work_path/$1
}

function chain() {
	awk "/^$1[[:space:]]+CHAIN/ { print \$3; }" $recipes_config
}

echo
echo -n 'name of ASYN: '
name asyn
echo -n 'repo of ASYN: '
repo asyn
echo -n 'tags of ASYN:'
for t in $(tag asyn)
do
	echo -n " $t"
done
echo

echo -n 'branches of ADCORE:'
for t in $(branch adcore)
do
	echo -n " $t"
done
echo

echo -n 'path of ADCORE: '
path adcore

echo -n 'chain of BAR: '
chain bar

echo
echo "success!"
exit 0
