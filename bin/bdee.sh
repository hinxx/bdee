#!/bin/bash
#
# Author  : Hinko Kocevar
# Created : 11 Sep 2019

# mod: bdee
# txt: Tools for building EPICS modules and IOCs.
#      Provides facilities for fetching sources from GIT repositories.
#      The individual packages are built from recipes containg list
#      of package names and versions; known as UIDs.
#      The list of known packages is in packages.cfg, and the list of
#      known recipes is in recipes.cfg.

# set -x
set -e
set -u


bdee_version=0.0.3

host_arch=linux-x86_64
work_path=$(pwd)
bin_path=$(realpath $(dirname $0))
share_path=$(realpath $(dirname $0)/../share)
packages_config=$share_path/packages.cfg
recipes_config=$share_path/recipes.cfg
recipe_config=$work_path/recipe.cfg
release_config=$work_path/RELEASE.local
site_config=$work_path/CONFIG_SITE.local
dist_location=/data/www/html/bdee/dist

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

function cfg_bins() {
  awk "/^$1[[:space:]]+BINS/ { print \$3; }" $packages_config
}

function find_recipe_chain() {
  awk "/^$1[[:space:]]+CHAIN/ { print \$3; }" $recipes_config
}

function find_recipe_name() {
  awk "/^$1[[:space:]]+CHAIN/ { print \$1; }" $recipes_config | head -n1
}

function get_recipe_chain() {
  awk "/[[:space:]]+CHAIN+[[:space:]]/ { print \$3; }" $recipe_config
}

function get_recipe_name() {
  awk "/[[:space:]]+CHAIN+[[:space:]]/ { print \$1; }" $recipe_config | head -n1
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

function dbg() { [[ -z $DEBUG ]] || echo -e "[DBG] $@ (${FUNCNAME[1]}:${BASH_LINENO[0]})" >&2; }
function inf() { echo -e "[INF] ${@} (${FUNCNAME[1]}:${BASH_LINENO[0]})" >&2; }
function err() { echo -e "\n[ERR] ${@} (${FUNCNAME[1]}:${BASH_LINENO[0]})\n" >&2; }

# fun: cmd_init recipe
# txt: This function should be called at least once once,
#      to generate config files used with later commands
# opt: recipe: recipe uid to work with
function cmd_init() {
  # recipe name comes from CLI
  local recipe0=$1
  if [[ -z $recipe0 ]]; then
    err missing recipe argument
    return 1
  fi

  # lookup recipe name from the list of known recipes
  local recipe=$(find_recipe_name $recipe0)
  if [[ -z $recipe ]]; then
    err recipe \'$recipe\' not found
    return 1
  fi
  # lookup the recipe chain from the list of known recipes
  local uids=$(find_recipe_chain $recipe)
  echo 'RECIPE        = '$recipe
  echo 'CHAIN         = '$uids
  echo

  if $(opt '-f'); then
    dbg removing existing config files..
    rm -f $recipe_config $release_config $site_config
  fi

  # create local recipe file specific to this build
  if [[ ! -f $recipe_config ]]; then
    inf CREATE $(basename $recipe_config) ..
    echo "# created $(date) by $USER @ $(hostname)" > $recipe_config
    echo "# recipe $recipe" >> $recipe_config
    for uid in $uids; do
      echo "$recipe CHAIN $uid" >> $recipe_config
    done
    # echo content:; cat $recipe_config
  else
    dbg exists $recipe_config ..
  fi

  if [[ ! -f $release_config ]]; then
    inf CREATE $(basename $release_config) ..
    echo "# created $(date) by $USER @ $(hostname)" > $release_config
    echo "# recipe $recipe" >> $release_config
    # use local recipe file specific to this build
    for uid in $(get_recipe_chain); do
      local name=$(pkg_name $uid)
      local path=$(pkg_path $name)
      local name_upper=$(pkg_name_variable $name)
      echo "$name_upper=$path" >> $release_config
    done
    # echo content:; cat $release_config
  else
    dbg exists $release_config ..
  fi

  if [[ ! -f $site_config ]]; then
    inf CREATE $(basename $site_config) ..
    echo "# created $(date) by $USER @ $(hostname)" > $site_config
    cat $share_path/CONFIG_SITE.local >> $site_config
    # echo content:; cat $site_config
  else
    dbg exists $site_config ..
  fi

  inf INIT DONE $recipe
}

# fun: cmd_prepare
# txt: This function prepares the packages for use with build
#      et. al. commands. It will:
#      * perform GIT clone, checkout
#      * adjust RELEASE and CONFIG_SITE files for EPICS packages
#      * call autogen.sh and configure for autotools based packages
#        to generate Makefile
function cmd_prepare() {
  local recipe=$(get_recipe_name)
  local uids=$(get_recipe_chain)
  echo 'RECIPE        = '$recipe
  echo 'CHAIN         = '$uids
  echo

  local opi_path=$work_path/opi
  local css_project=$opi_path/project.xml
  local css_dot_project=$opi_path/.project
  if [[ ! -d $opi_path ]]; then
    mkdir -p $opi_path || return 1
  fi

  # create CSS project file header if .project is missing
  if [[ ! -f $css_dot_project ]]; then
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $css_project
    echo '<projectDescription>' >> $css_project
    echo '<name>'$recipe' (DEV)</name>' >> $css_project
    echo '  <comment></comment>' >> $css_project
    echo '  <projects></projects>' >> $css_project
    echo '  <buildSpec></buildSpec>' >> $css_project
    echo '  <natures></natures>' >> $css_project
    echo '  <linkedResources>' >> $css_project
  fi

  local uid=
  for uid in $uids
  do
    local name=$(pkg_name $uid)
    local version=$(pkg_version $uid)
    local repo=$(cfg_repo $name)
    local path=$(pkg_path $name)
    local group=$(cfg_group $name)

    # clone the GIT repository if required
    if [[ ! -d $path ]]; then
      inf GIT CLONE $uid
      git clone $repo $name || return 1
    else
      dbg package $uid already cloned
    fi

    # checkout the version if required
    if [[ ! -d $path ]]; then
      err package $uid $path does NOT exists
      return 1
    else
      local state=$(git --git-dir $path/.git --work-tree $path branch)
      if [[ $state != "* $version" ]] && [[ $state != "* (HEAD detached at $version)" ]]; then
        inf GIT CHECKOUT $uid
        git --git-dir $path/.git --work-tree $path checkout $version || return 1
      else
        dbg package $uid already at version $version
      fi
    fi

    # pull the sources if requested from CLI
    if $(opt '-p'); then
      inf GIT PULL $uid
      git --git-dir $path/.git --work-tree $path pull || return 1
      dbg package $uid pulled sourced at version $version
    fi

    # link OPI folder into CSS project if folder exists
    local opi=$(cfg_opi $name)
    if [[ -n $opi ]]; then
      if [[ ! -h $opi_path/$name ]]; then
        inf DEV OPI LINK $uid
        ln -snf $path/$opi $opi_path/$name || return 1
        # create CSS project link entry  if .project is missing
        if [[ ! -f $css_dot_project ]]; then
          echo '    <link>' >> $css_project
          echo '      <name>'$name'</name>' >> $css_project
          echo '      <type>2</type>' >> $css_project
          echo '      <location>PROJECT_LOC/'$name'</location>' >> $css_project
          echo '    </link>' >> $css_project
        fi
        dbg package $uid OPI folder linked
      else
        dbg package $uid OPI folder already linked
      fi
    else
      dbg package $uid has no OPI folder
    fi

    # config package depending on the group
    if [[ $group = bases ]]; then
      if [[ ! -f $path/configure/CONFIG_SITE.local ]]; then
        inf CONFIG $uid
        cp $share_path/BASE_CONFIG_SITE.local $path/configure/CONFIG_SITE.local || return 1
      else
        dbg package $uid already exists ./configure/CONFIG_SITE.local
      fi
    elif [[ $group = modules ]] || [[ $group = iocs ]]; then
      if ! $(grep -q '^# BDEE local' $path/configure/RELEASE); then
        inf CONFIG $uid
        sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/RELEASE
        echo '# BDEE local RELEASE' >> $path/configure/RELEASE
        echo "include \$(TOP)/../RELEASE.local" >> $path/configure/RELEASE || return 1
      else
        dbg package $uid already updated ./configure/RELEASE
      fi
      if ! $(grep -q '^# BDEE local' $path/configure/CONFIG_SITE); then
        inf CONFIG $uid
        sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/CONFIG_SITE
        echo '# BDEE local CONFIG_SITE' >> $path/configure/CONFIG_SITE
        echo "include \$(TOP)/../CONFIG_SITE.local" >> $path/configure/CONFIG_SITE || return 1
      else
        dbg package $uid already updated ./configure/CONFIG_SITE
      fi
      if [[ $group = iocs ]]; then
        # set IOC application binary name
        echo PROD_NAME = $(pkg_app_name $name) > $path/CONFIG.local || return 1
      fi
    elif [[ $group = support ]]; then
      if [[ ! -f $path/configure ]]; then
        # try to use autogen.sh script to generate configure script
        if [[ -f $path/autogen.sh ]]; then
          pushd $path >/dev/null
          inf AUTOGEN $uid
          ./autogen.sh --prefix=$path $(cfg_config $name) || return 1
          popd >/dev/null
        else
          dbg package $uid ./autogen.sh NOT found
        fi
      fi
      if [[ ! -f $path/configure ]]; then
        # try to run autoreconf to generate configure script
        if [[ -f $path/configure.ac ]]; then
          pushd $path >/dev/null
          inf AUTORECONF $uid
          autoreconf -si || return 1
          popd >/dev/null
        else
          dbg package $uid configure.ac NOT found
        fi
      fi
      if [[ ! -f $path/Makefile ]]; then
        if [[ -f $path/configure ]]; then
          pushd $path >/dev/null
          inf CONFIG $uid
          ./configure --prefix=$path $(cfg_config $name) || return 1
          popd >/dev/null
        else
          dbg package $uid configure NOT found
        fi
      else
        dbg package $uid already has Makefile
      fi
      if [[ ! -f $path/Makefile ]]; then
        err package $uid source does NOT have Makefile
      fi
    fi
  done

  # create CSS project file footer if .project is missing
  if [[ ! -f $css_dot_project ]]; then
    echo '  </linkedResources>' >> $css_project
    echo '</projectDescription>' >> $css_project
    cp $css_project $css_dot_project || return 1
  fi

  inf PREPARE DONE $recipe
}

# fun: cmd_build
# txt: This function builds the individual packages from
#      source. It can also clean the source tree before the
#      build. In addition it created CSS project containing
#      the links to OPI folders of packages.
#      After successful build the artifacts are staged,
function cmd_build() {
  local recipe=$(get_recipe_name)
  local uids=$(get_recipe_chain)
  echo 'RECIPE        = '$recipe
  echo 'CHAIN         = '$uids
  echo

  local stage_path=$work_path/stage
  local opi_path=$stage_path/opi
  local css_project=$opi_path/project.xml
  local css_dot_project=$opi_path/.project

  # remove stage files, will be recreated in this function
  inf REMOVE STAGE $recipe
  rm -fr $stage_path
  mkdir -p $stage_path/{bin,db,dbd,ioc,log,autosave,opi}

  # create CSS project file header
  echo '<?xml version="1.0" encoding="UTF-8"?>' > $css_project
  echo '<projectDescription>' >> $css_project
  echo '<name>'$recipe'</name>' >> $css_project
  echo '  <comment></comment>' >> $css_project
  echo '  <projects></projects>' >> $css_project
  echo '  <buildSpec></buildSpec>' >> $css_project
  echo '  <natures></natures>' >> $css_project
  echo '  <linkedResources>' >> $css_project

  local silent=-s
  [[ -z $VERBOSE ]] || silent=

  local uid=
  for uid in $uids
  do
    local name=$(pkg_name $uid)
    local version=$(pkg_version $uid)
    local repo=$(cfg_repo $name)
    local path=$(pkg_path $name)
    local group=$(cfg_group $name)

    if [[ ! -d $path ]]; then
      err package $uid source does NOT exists
      return 1
    fi

    # clean the package if required
    if $(opt '-c'); then
      inf CLEAN $uid
      if [[ $group = bases ]] || [[ $group = modules ]] || [[ $group = iocs ]]; then
        make $silent -C $path -i -k uninstall realclean distclean clean || true
        find $path -name O.* | xargs rm -fr || true
      elif [[ $group = support ]]; then
        make $silent -C $path -i -k clean || true
        # XXX can not do this, because the autogen.sh/configure would need to be re-ran!
        # rm -f $path/configure $path/Makefile
      fi
    fi

    # build the package
    inf COMPILE $uid
    dbg make $silent -j -C $path install
    make $silent -j -C $path install || return 1

    # stage the package artifacts generated during the build
    inf STAGE $uid
    if [[ $group == bases ]]; then
      cp -a $path/db/* $stage_path/db || return 1
      cp -a $path/bin/$host_arch/{caput,caget,camonitor,caRepeater} $stage_path/bin || return 1
    elif [[ $group == modules ]]; then
      if [[ -d $path/db ]]; then
        cp -a $path/db/* $stage_path/db || return 1
      fi
      local bin_file=
      for bin_file in $(cfg_bins $name); do
        cp -a $path/bin/$host_arch/$bin_file $stage_path/bin || return 1
      done
    elif [[ $group == support ]]; then
      local bin_file=
      for bin_file in $(cfg_bins $name); do
        cp -a $path/bin/$bin_file $stage_path/bin || return 1
      done
    elif [[ $group == iocs ]]; then
      cp -a $path/bin/$host_arch/$(pkg_app_name $name) $stage_path/bin || return 1
      cp -a $path/dbd/$(pkg_app_name $name).dbd $stage_path/dbd || return 1
      if [[ -d $path/db ]]; then
        cp -a $path/db/* $stage_path/db || return 1
      fi
      cp -a $path/iocBoot/$name/* $stage_path/ioc || return 1
      cp -a $bin_path/start_ioc.sh $stage_path || return 1
      chmod +x $stage_path/start_ioc.sh
    fi

    # stage OPI files
    local opi=$(cfg_opi $name)
    if [[ -n $opi ]]; then
      if [[ ! -d $opi_path/$name ]]; then
        inf OPI $uid
        cp -a $path/$opi $opi_path/$name || return 1
        # create CSS project link entry
        echo '    <link>' >> $css_project
        echo '      <name>'$name'</name>' >> $css_project
        echo '      <type>2</type>' >> $css_project
        echo '      <location>PROJECT_LOC/'$name'</location>' >> $css_project
        echo '    </link>' >> $css_project
        dbg package $uid OPI folder copied
      else
        dbg package $uid OPI folder already copied
      fi
    else
      dbg package $uid has no OPI folder
    fi

  done

  # create CSS project file footer
  echo '  </linkedResources>' >> $css_project
  echo '</projectDescription>' >> $css_project
  cp $css_project $css_dot_project

  inf BUILD DONE $recipe
}

# fun: cmd_status
# txt: This functino show status of the package source. It
#      can also perform a diff if requested.
function cmd_status() {
  local recipe=$(get_recipe_name)
  local uids=$(get_recipe_chain)
  echo 'RECIPE        = '$recipe
  echo 'CHAIN         = '$uids
  echo

  local uid=
  for uid in $uids
  do
    local name=$(pkg_name $uid)
    local version=$(pkg_version $uid)
    local repo=$(cfg_repo $name)
    local path=$(pkg_path $name)
    local group=$(cfg_group $name)

    if [[ ! -d $path ]]; then
      err package $uid source does NOT exists
      return 1
    fi

    # perform git status on each package source
    inf GIT STATUS $uid
    git --git-dir $path/.git --work-tree $path status --short --branch || return 1

    # perform git diff on each package source if requested from CLI
    if $(opt '-d'); then
      inf GIT DIFF $uid
      git --git-dir $path/.git --work-tree $path --no-pager diff || return 1
    fi
  done

  inf STATUS DONE $recipe
}

# fun: cmd_release
# txt: This function creates an archive from the staged artifacts
#      and copies it to a distribution location.
function cmd_release() {
  local recipe=$(get_recipe_name)
  local uids=$(get_recipe_chain)
  echo 'RECIPE        = '$recipe
  echo 'CHAIN         = '$uids
  echo

  local stage_path=$work_path/stage
  if [[ ! -d $stage_path ]]; then
    err recipe $recipe stage does NOT exists
    return 1
  fi

  local archive_file=$recipe.sh
  inf ARCHIVE $recipe
  # using https://makeself.io/
  $bin_path/makeself.sh \
    --bzip2 \
    --nooverwrite \
    --tar-quietly \
    $stage_path \
    $archive_file \
    "BDEE recipe archive $recipe" \
    echo "DONE!" || return 1

  if [[ ! -d $dist_location ]]; then
    err destination $dist_location does NOT exists, can not upload
    return 1
  fi

  # remove the archive at destination if requested from CLI
  if $(opt '-r'); then
    rm -f $dist_location/$archive_file
  fi
  inf UPLOAD $recipe
  cp $archive_file $dist_location || return 1
  # make it read-only
  chmod a-w $dist_location/$archive_file || return 1
  inf updloaded $dist_location/$archive_file

  inf RELEASE DONE $recipe
}

# fun: usage
# txt: This function shows usage help.
function usage() {
  echo
  echo $(basename $0) command [command arguments] [common options]
  echo
  echo common options:
  echo "     -V               verbose execution of commands"
  echo "     -D               debug output"
  echo
  echo commands:
  echo " > init               initialize the working folder with config files"
  echo "     recipe           use recipe name from $recipes_config"
  echo "     -f               force regeneration of config files"
  echo " > prepare            prepare the recipe for building"
  echo "     -p               perform git pull after config"
  echo " > build              build the recipe"
  echo "     -c               perform clean before build"
  echo " > status             show status of the recipe"
  echo "     -d               perform git diff"
  echo " > release            pack artifacts and upload the archive"
  echo "     -r               remove the archive at destination folder"
  echo "     -l               destination folder"
  echo
  echo "tool version $bdee_version"
  echo
}

# fun: opt option
# txt: This function checks if the command line argument has been specified.
# opt: option: cli argument to check for
function opt() {
  [[ -n $1 ]] || return 1
  local pos=
  for pos in $ARGS; do
    if [[ $pos = $1 ]]; then return 0; fi
  done
  return 1
}


###########################################################################
###########################        MAIN        ############################
###########################################################################

# CLI arguments
#  - first is always command
#  - the rest are arguments to the command, handled in command context
[[ $# -gt 0 ]] || { usage; exit 1; }
CMD="$1"
shift
ARGS=
for i in "$@"; do
  ARGS="$ARGS $i"
done

VERBOSE=
if $(opt '-V'); then
  VERBOSE=YES
fi
DEBUG=
if $(opt '-D'); then
  DEBUG=YES
fi

echo
echo 'CMD           = '$CMD
echo 'ARGS          = '$ARGS
echo 'VERBOSE       = '$VERBOSE
echo 'DEBUG         = '$DEBUG

STATUS=0

if [[ $CMD = help ]]; then
  usage

elif [[ $CMD = init ]]; then
  cmd_init $ARGS || STATUS=1

elif [[ $CMD = prepare ]]; then
  cmd_prepare || STATUS=1

elif [[ $CMD = build ]]; then
  cmd_build || STATUS=1

elif [[ $CMD = status ]]; then
  cmd_status || STATUS=1

elif [[ $CMD = release ]]; then
  cmd_release || STATUS=1

else
   err unknown command \'$CMD\'
   STATUS=1
fi

if [[ $STATUS -eq 0 ]]; then
  echo; echo SUCCESS; echo
else
  echo; echo FAILED; echo
fi

exit $STATUS
