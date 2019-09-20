#!/bin/bash
#

# set -x

host_arch=linux-x86_64
work_path=$(pwd)
bin_path=$(realpath $(dirname $0))
share_path=$(realpath $(dirname $0)/../share)
packages_config=$share_path/packages.cfg
recipes_config=$share_path/recipes.cfg

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

function cfg_opi() {
  awk "/^$1[[:space:]]+OPI/ { print \$3; }" $packages_config
}

function cfg_chain() {
  awk "/^$1[[:space:]]+CHAIN/ { print \$3; }" $recipes_config
}

function pkg_app_name() {
  echo $1 | sed -e 's/ioc$/App/'
}

function pkg_path() {
  echo $work_path/$1
}

function pkg_name() {
  echo "$1" | cut -f1 -d:
}

function pkg_name_variable() {
  echo $1 | tr [a-z] [A-Z] | tr '-' '_'
}

function pkg_version() {
  echo "$1" | cut -f2 -d:
}

function pkg_filter() {
  if [[ -z "$2" ]]; then
    # echo $1
    return 0
  fi
  local package=
  for package in $2; do
    if [[ $package = $1 ]]; then
      # echo $1
      return 0
    fi
  done
  return 1
}

function generate_meta() {
  # rm -f recipe.meta
  echo "# created $(date) by $USER @ $(hostname)" > recipe.meta
  for uid in $(cfg_chain $1)
  do
    echo "$uid" >> recipe.meta
  done
}

function generate_release_local() {
  local f=RELEASE.local
  # XXX: should we ever replace this? Maybe with force..
  # if [[ -f $f ]]; then
  #   echo $f already exists
  #   return 0
  # fi
  echo "# created $(date) by $USER @ $(hostname)" > $f
  for uid in $(cfg_chain $1)
  do
    local name=$(pkg_name $uid)
    local path=$(pkg_path $name)
    local name_upper=$(pkg_name_variable $name)
    echo "$name_upper=$path" >> $f
  done
  # echo $f content for chain $1:; cat $f
  echo created $f
}

function generate_configsite_local() {
  local f=CONFIG_SITE.local
  # XXX: should we ever replace this? Maybe with force..
  # if [[ -f $f ]]; then
  #   echo $f already exists
  #   return 0
  # fi
  echo "# created $(date) by $USER @ $(hostname)" > $f
  cat $share_path/CONFIG_SITE.local >> $f
  # echo $f content for chain $1:; cat $f
  echo created $f
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

function checkout_prerun() {
  local opi_path=$work_path/opi
  if [[ ! -d $opi_path ]]; then
    mkdir -p $opi_path
  fi
}

function checkout() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not checkout
    return 1
  fi

  # TODO: Should we check for current branch/tag or
  # just perform checkout? See git describe --all.
  echo git --git-dir $path/.git --work-tree $path checkout $2
  git --git-dir $path/.git --work-tree $path checkout $2

  local opi_path=$work_path/opi
  local opi=$(cfg_opi $1)
  if [[ -n $opi ]]; then
    if [[ ! -h $opi_path/$1 ]]; then
      ln -snf $path/$opi $opi_path/$1
    fi
  fi
}

function checkout_postrun() {
  local opi_path=$work_path/opi
  if [[ ! -d $opi_path ]]; then
    echo path $opi_path does NOT exists, can not do post checkout
    return 1
  fi
  cat << EOF > $opi_path/.project
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
  <name>--devel-- $1</name>
  <comment></comment>
  <projects></projects>
  <buildSpec></buildSpec>
  <natures></natures>
  <linkedResources>
EOF
  pushd $opi_path >/dev/null
  local folders=$(find . -mindepth 1 -maxdepth 1 -type l)
  for folder in $folders; do
    cat << EOF >> $opi_path/.project
    <link>
      <name>$folder</name>
      <type>2</type>
      <location>PROJECT_LOC/$folder</location>
    </link>
EOF
  done
  popd >/dev/null
  cat << EOF >> $opi_path/.project
  </linkedResources>
</projectDescription>
EOF
}

function pull() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not pull
    return 1
  fi

  echo git --git-dir $path/.git --work-tree $path pull
  git --git-dir $path/.git --work-tree $path pull
}

function status() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not get status
    return 1
  fi

  echo git --git-dir $path/.git --work-tree $path status
  git --git-dir $path/.git --work-tree $path status
}

function diff() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not diff
    return 1
  fi

  echo git --git-dir $path/.git --work-tree $path diff
  git --git-dir $path/.git --work-tree $path diff
}

function config() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not config
    return 1
  fi

  local group=$(cfg_group $1)
  if [[ $group = bases ]]; then
    if [[ ! -f $path/configure/CONFIG_SITE.local ]]; then
      cp $share_path/BASE_CONFIG_SITE.local $path/configure/CONFIG_SITE.local
      echo package $1 created $path/configure/CONFIG_SITE.local
    else
      echo package $1 already exists $path/configure/CONFIG_SITE.local
    fi
    return 0
  elif [[ $group = modules ]] || [[ $group = iocs ]]; then
    local skip=YES
    grep -q "^# BDEE local" $path/configure/RELEASE || skip=NO
    if [[ $skip = NO ]]; then
      echo package $1 configure/RELEASE update
      sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/RELEASE
      echo '# BDEE local RELEASE' >> $path/configure/RELEASE
      echo "include \$(TOP)/../RELEASE.local" >> $path/configure/RELEASE
    else
      echo package $1 configure/RELEASE already updated
    fi
    local skip=YES
    grep -q "^# BDEE local" $path/configure/CONFIG_SITE || skip=NO
    if [[ $skip = NO ]]; then
      echo package $1 configure/CONFIG_SITE update
      sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/CONFIG_SITE
      echo '# BDEE local CONFIG_SITE' >> $path/configure/CONFIG_SITE
      echo "include \$(TOP)/../CONFIG_SITE.local" >> $path/configure/CONFIG_SITE
    else
      echo package $1 configure/CONFIG_SITE already updated
    fi
    if [[ $group = iocs ]]; then
      # set IOC application binary name
      echo PROD_NAME = $(pkg_app_name $1) > $path/CONFIG.local
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

function stage_prerun() {
  local stage_path=$work_path/stage
  rm -fr $stage_path
  mkdir -p $stage_path/{bin,db,dbd,ioc,log,autosave,opi}
}

function stage() {
  local path=$(pkg_path $1)
  if [[ ! -d $path ]]; then
    echo package $1 path $path does NOT exists, can not stage
    return 1
  fi

  local stage_path=$work_path/stage
  local group=$(cfg_group $1)
  if [[ $group == bases ]]; then
    cp -a $path/db/* $stage_path/db
    cp -a $path/bin/$host_arch/{caput,caget,camonitor,caRepeater} $stage_path/bin
  elif [[ $group == modules ]]; then
    if [[ -d $path/db ]]; then
      cp -a $path/db/* $stage_path/db
    fi
  elif [[ $group == iocs ]]; then
    cp -a $path/bin/$host_arch/$(pkg_app_name $1) $stage_path/bin
    cp -a $path/dbd/$(pkg_app_name $1).dbd $stage_path/dbd
    if [[ -d $path/db ]]; then
      cp -a $path/db/* $stage_path/db
    fi
    cp -a $path/iocBoot/$1/* $stage_path/ioc
    cp -a $bin_path/start_ioc.sh $stage_path
    chmod +x $stage_path/start_ioc.sh
  fi

  local opi_path=$stage_path/opi
  local opi=$(cfg_opi $1)
  if [[ -n $opi ]]; then
    if [[ ! -d $opi_path/$1 ]]; then
      cp -a $path/$opi $opi_path/$1
    fi
  fi
}

function stage_postrun() {
  local opi_path=$work_path/stage/opi
  if [[ ! -d $opi_path ]]; then
    echo path $opi_path does NOT exists, can not do post stage
    return 1
  fi
  cat << EOF > $opi_path/.project
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
  <name>$1</name>
  <comment></comment>
  <projects></projects>
  <buildSpec></buildSpec>
  <natures></natures>
  <linkedResources>
EOF
  pushd $opi_path >/dev/null
  local folders=$(find . -mindepth 1 -maxdepth 1 -type d)
  for folder in $folders; do
    cat << EOF >> $opi_path/.project
    <link>
      <name>$folder</name>
      <type>2</type>
      <location>PROJECT_LOC/$folder</location>
    </link>
EOF
  done
  popd >/dev/null
  cat << EOF >> $opi_path/.project
  </linkedResources>
</projectDescription>
EOF
}

function provide() {
  clone $1
  checkout $1 $2
  config $1
  build $1
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

function pack() {
  local stage_path=$work_path/stage
  if [[ ! -d $stage_path ]]; then
    echo stage_path $stage_path does NOT exists, can not pack
    return 1
  fi

  # from https://makeself.io/
  $bin_path/makeself.sh \
    --bzip2 \
    --nooverwrite \
    --tar-quietly \
    $stage_path \
    $1-$2.sh \
    "BDEE $1-$2" \
    echo "DONE!"
}

###########################################################################
function usage() {
  echo
  echo $(basename $0) command recipe [-h] [-p list] [-v] [-c]
  echo
  echo options:
  echo "  -c              execute command on whole chain of packages (default no)"
  echo "  -h              this text"
  echo "  -p list         list of packages to work on (optional)"
  echo "  -v              verbose command execution (default no)"
  echo
}

CMD=
RECIPE=
PACKAGE_LIST=
VERBOSE=NO
UIDS=
CHAIN=NO
POSITIONAL=()

while [[ $# -gt 0 ]]; do
key="$1"
case $key in
  -h)
  usage
  exit 0
  ;;
  -c)
  CHAIN=YES
  shift # past argument
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
echo "CHAIN         = $CHAIN"
echo "PACKAGE LIST  = $PACKAGE_LIST"
echo "POSITIONAL    = ${POSITIONAL[@]}"

generate_meta $RECIPE
generate_release_local $RECIPE
generate_configsite_local $RECIPE

# get list of uids from the recipe chain
UIDS=$(cfg_chain $RECIPE)
if [[ $CHAIN = NO ]]; then
  # only act on last uid in the chain
  UIDS=$(echo $UIDS | grep -o '[^ ]\+$')
fi
# reverse the uid list if required
if [[ $CMD = clean ]]; then
  UIDS=$(echo "$UIDS" | tac)
fi
echo UIDS: $UIDS

# prerun before diving into chain
case $CMD in
  checkout)   checkout_prerun ;;
  stage)      stage_prerun ;;
  *) echo no prerun for command \'$CMD\'.. ;;
esac

for uid in $UIDS
do
  name=$(pkg_name $uid)
  version=$(pkg_version $uid)
  echo

  skip=
  pkg_filter $name "$PACKAGE_LIST" || skip=1
  if [[ -n $skip ]]; then
    echo skipping package uid $uid
    continue
  fi

  echo handling package uid $uid

  case $CMD in
    clone)      clone $name ;;
    checkout)   checkout $name $version ;;
    config)     config $name ;;
    build)      build $name ;;
    provide)    provide $name $version ;;
    stage)      stage $name ;;
    clean)      clean $name ;;
    pull)       pull $name ;;
    status)     status $name ;;
    diff)       diff $name ;;
    pack)       pack $name $version ;;

    *) echo unknown command \'$CMD\', aborting!; exit 1 ;;
  esac

  echo
done

# postrun before diving into chain
case $CMD in
  checkout)   checkout_postrun $RECIPE ;;
  stage)      stage_postrun $RECIPE ;;
  *) echo no postrun for command \'$CMD\'.. ;;
esac

echo
echo "success!"
exit 0
