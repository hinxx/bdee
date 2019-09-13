#!/bin/bash
#

# set -x

packages_dir=$(realpath $(dirname $0)/../packages)
recipes_dir=$(realpath $(dirname $0)/../recipes)
packages_config=$(realpath $(dirname $0)/../packages/packages.ini)
recipes_config=$(realpath $(dirname $0)/../recipes/recipes.ini)

function _get_packages() {
	pushd $packages_dir >/dev/null
	ls *.pkg
	popd >/dev/null
}

function _get_recipes() {
	pushd $recipes_dir >/dev/null
	ls *.rcp
	popd >/dev/null
}

package_files=$(_get_packages)
recipe_files=$(_get_recipes)

recipe_uid="$1"
echo "handling recipe uid $recipe_uid"
[[ -n $recipe_uid ]] || { echo "usage: $0 <recipe uid>"; exit 1; }
recipe_file=$(echo $recipe_uid | tr ':' '-')

function packages_get_section() {
	# get single ini section
	sed -n "0,/$1/d;/\[/,\$d;/^$/d;p" $packages_config
}

function recipes_get_section() {
	# get single ini section
	sed -n "0,/$1/d;/\[/,\$d;/^$/d;p" $recipes_config
}

function get_option() {
	# get single ini option from a section
	sed -n "0,/$1/d;/=/,\$d;/^$/d;p" $2
}



function test2() {
	# get all ini sections as associative arrays
	declare -A package_names
	IFS='
	'
	while read -r line
	do
	  echo line $line
	  # if [[ $line =~ "^\[.*\]$" ]]; then
	  if [[ $line =~ ^\[.*\]$ ]]; then
	    echo "SECTION: $line"
	    section=$(echo $line | sed -e 's/\[//' -e 's/\]//')
	    package_names[$section]=foo
	  fi
	done < $packages_config

	for K in "${!package_names[@]}"; do echo DUMP $K; done
}

# packages=$(grep '^\[' $packages_config | sed -e 's/\[//' -e 's/\]//')
# echo packages: $packages
# for p in $packages
# do
# 	tmp=$(tempfile -p bdee-)
# 	packages_get_section $p > $tmp
# done

# set -x
# recipes_get_section 'foo'
# recipes_get_section 'adcore-first'
# recipes_get_section 'barr'
# set +x


function recipes_check_uids() {
	local ifs=$IFS
	IFS='
'
	local ok=0
	for uid in $(grep '^\[' $recipes_config)
	do
		# not ending with ]
		echo $uid | grep -q '\]$' || {
			echo "invalid recipe uid: '$uid'"
			ok=1
		}
		# has whitespace in the name
		# echo $uid | grep -q -v "[[:space:]]" || {
		# 	echo "invalid recipe uid: '$uid'"
		# 	ok=1
		# }
	done
	IFS=$ifs
	echo returning ok=$ok
	return $ok
}

function uid_strip_brackets() {
	echo "$1" | sed \
		-e 's/\[//' \
		-e 's/\]//'
}

function uid_sanitize() {
	echo "$1" | sed \
		-e 's/[~@#$%&+=\/]/_/g' \
		-e 's/[[:space:]]/_/g' \
		-e 's/-/_/g'
}

function recipes_get_uids() {
	local ifs=$IFS
	IFS='
'
	local sanitized=
	for uid in $(grep '^\[' $recipes_config)
	do
		uid=$(uid_strip_brackets "$uid")
		sanitized=$(uid_sanitize "$uid")
		echo SANITIZED "$uid" '>>>' $sanitized
		local tmp=$(tempfile)
		tmp=/tmp/f
		recipes_get_section "$uid" > $tmp
		# work with section in subshell
		(
			get_option "CHAIN" $tmp

			# read whole file and remove new lines
			# sed -e ':a;N;$!ba;s/\n/ /g' $tmp
			
			# sed -e 's/\s=\s/="/' -e 's/$/\"/' $tmp
		)
		# rm -f $tmp
	done
	IFS=$ifs
}

# recipes=$(grep '^\[' $recipes_config | sed -e 's/\[//' -e 's/\]//')
# echo recipes: $recipes
# for p in $packages
# do
# 	tmp=$(tempfile -p bdee-)
# 	recipes_get_section $p > $tmp
# done

recipes_check_uids
recipes_get_uids

echo "success!"
exit 0
