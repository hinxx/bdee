#!/bin/bash
#

set -x

packages_dir=$(realpath $(dirname $0)/../packages)
recipes_dir=$(realpath $(dirname $0)/../recipes)

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


echo "success!"
exit 0
