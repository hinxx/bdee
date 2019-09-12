#!/bin/bash
#

# set -x

packages_dir=$(realpath $(dirname $0)/../packages)
recipes_dir=$(realpath $(dirname $0)/../recipes)
packages_config=$(realpath $(dirname $0)/../packages/packages.ini)

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

# get single ini section
# sed -n "1,/asyn/d;/\[/,\$d;/^$/d;p" $packages_config

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

echo "success!"
exit 0
