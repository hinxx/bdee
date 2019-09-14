#!/bin/bash
#

# set -x

packages_config=$(realpath $(dirname $0)/../packages/packages.cfg)
recipes_config=$(realpath $(dirname $0)/../recipes/recipes.cfg)
files_path=$(realpath $(dirname $0)/../files)
work_path=$(pwd)

function cfg_name() {
  awk "/^$1[[:space:]]+NAME/ { print \$3; }" $packages_config
}

function cfg_group() {
  awk "/^$1[[:space:]]+GROUP/ { print \$3; }" $packages_config
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

function cfg_config() {
  awk "/^$1[[:space:]]+CONFIG/ { print \$3; }" $packages_config
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

function generate_meta() {
  rm -f recipe.meta
  echo "# created $(date) by $USER @ $(hostname)" >> recipe.meta
  for uid in $(cfg_chain $1)
  do
    echo "$uid" >> recipe.meta
  done
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

  local group=$(cfg_group $1)
  if [[ $group = bases ]]; then
    echo nothing to configure for epics-base..
    return 0
  elif [[ $group = modules ]] || [[ $group = iocs ]]; then
    if [[ -z $(grep -q "^# BDEE local RELEASE$" $path/configure/RELEASE) ]]; then
      echo package $1 configure/RELEASE update
      sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/RELEASE
      echo '# BDEE local RELEASE' >> $path/configure/RELEASE
      echo "include \$(TOP)/../RELEASE.local" >> $path/configure/RELEASE
    else
      echo package $1 configure/RELEASE already updated
    fi
    if [[ -z $(grep -q "^# BDEE local CONFIG_SITE$" $path/configure/CONFIG_SITE) ]]; then
      echo package $1 configure/CONFIG_SITE update
      sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/CONFIG_SITE
      echo '# BDEE local CONFIG_SITE' >> $path/configure/CONFIG_SITE
      echo "include \$(TOP)/../CONFIG_SITE.local" >> $path/configure/CONFIG_SITE
    else
      echo package $1 configure/CONFIG_SITE already updated
    fi
  elif [[ $group = support ]]; then
    if [[ ! -f $path/configure ]]; then
      # try to use autogen.sh script to generate configure script
      if [[ -f $path/autogen.sh ]]; then
        pushd $path >/dev/null
        echo ./autogen.sh --prefix=$path $(cfg_config $1)
        ./autogen.sh --prefix=$path $(cfg_config $1)
        popd >/dev/null
      else
        echo autogen.sh not found in $path
      fi
    fi
    if [[ ! -f $path/configure ]]; then
      # try to run autoreconf to generate configure script
      if [[ -f $path/configure.ac ]]; then
        pushd $path >/dev/null
        echo autoreconf -si
        autoreconf -si
        popd >/dev/null
      else
        echo configure.ac not found in $path
      fi
    fi
    if [[ ! -f $path/Makefile ]]; then
      if [[ -f $path/configure ]]; then
        pushd $path >/dev/null
        echo ./configure --prefix=$path $(cfg_config $1)
        ./configure --prefix=$path $(cfg_config $1)
        popd >/dev/null
      else
        echo configure not found in $path
      fi
    fi
    [[ -f $path/Makefile ]] || echo source $path does not contain Makefile
  fi
}

function build() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not build
    return 1
  fi

  local silent=-s
  [[ $VERBOSE = NO ]] || silent=
  echo make $silent -j -C $path install
  make $silent -j -C $path install
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

###########################################################################
function usage() {
  echo
  echo $(basename $0) command recipe [-h] [-R list]
  echo
  echo options:
  echo "  -h              this text"
  echo "  -p list         list of packages to work on (optional)"
  echo
}

CMD=
RECIPE=
PACKAGE_LIST=
VERBOSE=NO
POSITIONAL=()

while [[ $# -gt 0 ]]; do
key="$1"
case $key in
  -h)
  usage
  exit 0
  ;;
  -p)
  PACKAGE_LIST="$2"
  shift # past argument
  shift # past value
  ;;
  -v)
  VERBOSE=YES
  shift # past argument
  ;;

  *)    # unknown option
  POSITIONAL+=("$1") # save it in an array for later
  shift # past argument
  ;;
esac
done

if [[ ${#POSITIONAL[@]} -gt 1 ]]; then
  CMD=${POSITIONAL[0]}
  RECIPE=${POSITIONAL[1]}
  # remove 0th and 1st element
  unset POSITIONAL[0]
  unset POSITIONAL[1]
elif [[ ${#POSITIONAL[@]} -gt 0 ]]; then
  CMD=${POSITIONAL[0]}
  # remove 0th element
  unset POSITIONAL[0]
fi
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
  POSITIONAL=( "${POSITIONAL[@]}" )
else
  POSITIONAL=()
fi

[[ -n $CMD ]] || { usage; exit 1; }
[[ -n $RECIPE ]] || { usage; exit 1; }

echo "CMD           = $CMD"
echo "RECIPE        = $RECIPE"
echo "PACKAGE LIST  = $PACKAGE_LIST"
echo "POSITIONAL    = ${POSITIONAL[@]}"

generate_meta $RECIPE
generate_release_local $RECIPE
generate_configsite_local $RECIPE

uids=$(cfg_chain $RECIPE)
if [[ $CMD = clean ]]; then
  uids=$(echo "$uids" | tac)
fi
echo uids: $uids

for uid in $uids
do
  echo
  echo package uid: $uid
  clone $(pkg_name $uid)
  checkout $(pkg_name $uid) $(pkg_version $uid)
  config $(pkg_name $uid)
  build $(pkg_name $uid)
  echo
done

echo
echo "success!"
exit 0
