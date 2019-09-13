#!/bin/bash
#

# set -x

packages_config=$(realpath $(dirname $0)/../packages/packages.cfg)
recipes_config=$(realpath $(dirname $0)/../recipes/recipes.cfg)
files_path=$(realpath $(dirname $0)/../files)
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


function cfg_name() {
	awk "/^$1[[:space:]]+NAME/ { print \$3; }" $packages_config
}

function cfg_repo() {
	awk "/^$1[[:space:]]+REPO/ { print \$3; }" $packages_config
}

function cfg_tag() {
	awk "/^$1[[:space:]]+TAG/ { print \$3; }" $packages_config
}

function cfg_branch() {
	awk "/^$1[[:space:]]+BRANCH/ { print \$3; }" $packages_config
}

function cfg_remote() {
	awk "/^$1[[:space:]]+REMOTE/ { print \$3; }" $packages_config
}

function cfg_chain() {
	awk "/^$1[[:space:]]+CHAIN/ { print \$3; }" $recipes_config
}

function pkg_path() {
	echo $work_path/$1
}

function pkg_name() {
	echo "$1" | cut -f1 -d:
}

function pkg_version() {
	echo "$1" | cut -f2 -d:
}

function test1() {

	echo
	echo -n 'name of ASYN: '
	name asyn
	echo
	echo -n 'repo of ASYN: '
	repo asyn
	echo
	echo -n 'remote of ASYN: '
	remote asyn
	echo
	echo -n 'tags of ASYN:'
	for t in $(tag asyn)
	do
		echo -n " $t"
	done
	echo

	echo
	echo -n 'branches of ADCORE:'
	for t in $(branch adcore)
	do
		echo -n " $t"
	done
	echo

	echo
	echo -n 'path of ADCORE: '
	path adcore

	echo
	echo -n 'chain of BAR:'
	for t in $(chain bar)
	do
		echo -n " $t"
	done
	echo
}

function generate_release_local() {
	rm -f RELEASE.local
	echo "# created $(date) by $USER @ $(hostname)" >> RELEASE.local
	for uid in $(cfg_chain $1)
	do
		local name=$(pkg_name $uid)
		local path=$(pkg_path $name)
		local name_upper=$(echo $name | tr [a-z] [A-Z] | tr '-' '_')
		echo "$name_upper=$path" >> RELEASE.local
	done
	# echo RELEASE.local content for chain $1:; cat RELEASE.local
}

function generate_configsite_local() {
	rm -f CONFIG_SITE.local
	echo "# created $(date) by $USER @ $(hostname)" >> CONFIG_SITE.local
	cat $files_path/CONFIG_SITE.local >> CONFIG_SITE.local
	# echo CONFIG_SITE.local content for chain $1:; cat CONFIG_SITE.local
}

function clone() {
	local repo=$(cfg_repo $1)
	local path=$(pkg_path $1)
	if [[ -d $path ]]; then
		echo package $1 path $path exists, not cloning repo $repo
		return 0
	fi

	echo git clone $repo $1
	git clone $repo $1
}

function checkout() {
	local path=$(pkg_path $1)
	if [[ ! -d $path ]]; then
		echo package $1 path $path does NOT exists, can not checkout
		return 1
	fi

	# TODO: Should we check for current branch/tag or
	# just perform checkout? See git describe --all.
	echo git -C $path checkout $2
	git -C $path checkout $2
}

function config() {
	local path=$(pkg_path $1)
	if [[ ! -d $path ]]; then
		echo package $1 path $path does NOT exists, can not config
		return 1
	fi

	if [[ $1 = 'epics-base' ]]; then
		echo nothing to configure for epics-base..
		return 0
	fi

	grep -q "^# BDEE local RELEASE$" $path/configure/RELEASE
	if [[ $? -ne 0 ]]; then
		echo package $1 configure/RELEASE update
		sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/RELEASE
		echo '# BDEE local RELEASE' >> $path/configure/RELEASE
		echo "include \$(TOP)/../RELEASE.local" >> $path/configure/RELEASE
	else
		echo package $1 configure/RELEASE already updated
	fi

	grep -q "^# BDEE local CONFIG_SITE$" $path/configure/CONFIG_SITE
	if [[ $? -ne 0 ]]; then
		echo package $1 configure/CONFIG_SITE update
		sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/CONFIG_SITE
		echo '# BDEE local CONFIG_SITE' >> $path/configure/CONFIG_SITE
		echo "include \$(TOP)/../CONFIG_SITE.local" >> $path/configure/CONFIG_SITE
	else
		echo package $1 configure/CONFIG_SITE already updated
	fi
}

function build() {
	local path=$(pkg_path $1)
	if [[ ! -d $path ]]; then
		echo package $1 path $path does NOT exists, can not build
		return 1
	fi

	echo make -j -C $path
	make -j -C $path
}

function clean() {
	local path=$(pkg_path $1)
	if [[ ! -d $path ]]; then
		echo package $1 path $path does NOT exists, can not clean
		return 1
	fi

	echo make -C $path clean
	make -C $path clean
}

CMD=$1
CHAIN=$2

generate_release_local $CHAIN
generate_configsite_local $CHAIN

uids=$(cfg_chain $CHAIN)
if [[ $CMD = clean ]]; then
	uids=$(echo "$uids" | tac)
fi
echo uids: $uids
exit 33

for uid in $uids
do
	echo
	echo package uid: $uid
	clone $(pkg_name $uid)
	checkout $(pkg_name $uid) $(pkg_version $uid)
	config $(pkg_name $uid)
	# build $(pkg_name $uid)
	echo
done

echo
echo "success!"
exit 0
