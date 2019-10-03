#!/bin/bash
#

# set -x
set -e
set -u

# mod: bdee
# txt: this module is for building EPICS modules and IOCs.

bdee_version=0.0.1

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

function find_chain() {
  awk "/^$1[[:space:]]+CHAIN/ { print \$3; }" $recipes_config
}

function find_chain_name() {
  awk "/^$1[[:space:]]+CHAIN/ { print \$1; }" $recipes_config | head -n1
}

function load_chain() {
  awk "/[[:space:]]+CHAIN+[[:space:]]/ { print \$3; }" $recipe_config
}

function load_chain_name() {
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

# function generate_meta() {
#   # rm -f recipe.meta
#   echo "# created $(date) by $USER @ $(hostname)" > recipe.meta
#   for uid in $(cfg_chain $1)
#   do
#     echo "$uid" >> recipe.meta
#   done
# }

# function generate_release_local() {
#   local f=RELEASE.local
#   # XXX: should we ever replace this? Maybe with force..
#   # if [[ -f $f ]]; then
#   #   echo $f already exists
#   #   return 0
#   # fi
#   echo "# created $(date) by $USER @ $(hostname)" > $f
#   for uid in $(cfg_chain $1)
#   do
#     local name=$(pkg_name $uid)
#     local path=$(pkg_path $name)
#     local name_upper=$(pkg_name_variable $name)
#     echo "$name_upper=$path" >> $f
#   done
#   # echo $f content for chain $1:; cat $f
#   echo created $f
# }

# function generate_configsite_local() {
#   local f=CONFIG_SITE.local
#   # XXX: should we ever replace this? Maybe with force..
#   # if [[ -f $f ]]; then
#   #   echo $f already exists
#   #   return 0
#   # fi
#   echo "# created $(date) by $USER @ $(hostname)" > $f
#   cat $share_path/CONFIG_SITE.local >> $f
#   # echo $f content for chain $1:; cat $f
#   echo created $f
# }

# function clone() {
#   local repo=$(cfg_repo $1)
#   local path=$(pkg_path $1)
#   if [[ -d $path ]]; then
#     echo package $1 path $path exists, not cloning repo $repo
#     return 0
#   fi

#   echo git clone $repo $1
#   git clone $repo $1
# }

# function checkout_prerun() {
#   local opi_path=$work_path/opi
#   if [[ ! -d $opi_path ]]; then
#     mkdir -p $opi_path
#   fi
# }

# function checkout() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not checkout
#     return 1
#   fi

#   # TODO: Should we check for current branch/tag or
#   # just perform checkout? See git describe --all.
#   echo git --git-dir $path/.git --work-tree $path checkout $2
#   git --git-dir $path/.git --work-tree $path checkout $2

#   local opi_path=$work_path/opi
#   local opi=$(cfg_opi $1)
#   if [[ -n $opi ]]; then
#     if [[ ! -h $opi_path/$1 ]]; then
#       ln -snf $path/$opi $opi_path/$1
#     fi
#   fi
# }

# function checkout_postrun() {
#   local opi_path=$work_path/opi
#   if [[ ! -d $opi_path ]]; then
#     echo path $opi_path does NOT exists, can not do post checkout
#     return 1
#   fi
#   cat << EOF > $opi_path/.project
# <?xml version="1.0" encoding="UTF-8"?>
# <projectDescription>
#   <name>--devel-- $1</name>
#   <comment></comment>
#   <projects></projects>
#   <buildSpec></buildSpec>
#   <natures></natures>
#   <linkedResources>
# EOF
#   pushd $opi_path >/dev/null
#   local folders=$(find . -mindepth 1 -maxdepth 1 -type l)
#   for folder in $folders; do
#     cat << EOF >> $opi_path/.project
#     <link>
#       <name>$folder</name>
#       <type>2</type>
#       <location>PROJECT_LOC/$folder</location>
#     </link>
# EOF
#   done
#   popd >/dev/null
#   cat << EOF >> $opi_path/.project
#   </linkedResources>
# </projectDescription>
# EOF
# }

# function pull() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not pull
#     return 1
#   fi

#   echo git --git-dir $path/.git --work-tree $path pull
#   git --git-dir $path/.git --work-tree $path pull
# }

# function status() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not get status
#     return 1
#   fi

#   echo git --git-dir $path/.git --work-tree $path status
#   git --git-dir $path/.git --work-tree $path status
# }

# function diff() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not diff
#     return 1
#   fi

#   echo git --git-dir $path/.git --work-tree $path diff
#   git --git-dir $path/.git --work-tree $path diff
# }

# # function config() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not config
#     return 1
#   fi

#   local group=$(cfg_group $1)
#   if [[ $group = bases ]]; then
#     if [[ ! -f $path/configure/CONFIG_SITE.local ]]; then
#       cp $share_path/BASE_CONFIG_SITE.local $path/configure/CONFIG_SITE.local
#       echo package $1 created $path/configure/CONFIG_SITE.local
#     else
#       echo package $1 already exists $path/configure/CONFIG_SITE.local
#     fi
#     return 0
#   elif [[ $group = modules ]] || [[ $group = iocs ]]; then
#     local skip=YES
#     grep -q "^# BDEE local" $path/configure/RELEASE || skip=NO
#     if [[ $skip = NO ]]; then
#       echo package $1 configure/RELEASE update
#       sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/RELEASE
#       echo '# BDEE local RELEASE' >> $path/configure/RELEASE
#       echo "include \$(TOP)/../RELEASE.local" >> $path/configure/RELEASE
#     else
#       echo package $1 configure/RELEASE already updated
#     fi
#     local skip=YES
#     grep -q "^# BDEE local" $path/configure/CONFIG_SITE || skip=NO
#     if [[ $skip = NO ]]; then
#       echo package $1 configure/CONFIG_SITE update
#       sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/CONFIG_SITE
#       echo '# BDEE local CONFIG_SITE' >> $path/configure/CONFIG_SITE
#       echo "include \$(TOP)/../CONFIG_SITE.local" >> $path/configure/CONFIG_SITE
#     else
#       echo package $1 configure/CONFIG_SITE already updated
#     fi
#     if [[ $group = iocs ]]; then
#       # set IOC application binary name
#       echo PROD_NAME = $(pkg_app_name $1) > $path/CONFIG.local
#     fi
#   elif [[ $group = support ]]; then
#     if [[ ! -f $path/configure ]]; then
#       # try to use autogen.sh script to generate configure script
#       if [[ -f $path/autogen.sh ]]; then
#         pushd $path >/dev/null
#         echo ./autogen.sh --prefix=$path $(cfg_config $1)
#         ./autogen.sh --prefix=$path $(cfg_config $1)
#         popd >/dev/null
#       else
#         echo autogen.sh not found in $path
#       fi
#     fi
#     if [[ ! -f $path/configure ]]; then
#       # try to run autoreconf to generate configure script
#       if [[ -f $path/configure.ac ]]; then
#         pushd $path >/dev/null
#         echo autoreconf -si
#         autoreconf -si
#         popd >/dev/null
#       else
#         echo configure.ac not found in $path
#       fi
#     fi
#     if [[ ! -f $path/Makefile ]]; then
#       if [[ -f $path/configure ]]; then
#         pushd $path >/dev/null
#         echo ./configure --prefix=$path $(cfg_config $1)
#         ./configure --prefix=$path $(cfg_config $1)
#         popd >/dev/null
#       else
#         echo configure not found in $path
#       fi
#     fi
#     [[ -f $path/Makefile ]] || echo source $path does not contain Makefile
#   fi
# }

# function build() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not build
#     return 1
#   fi

#   local silent=-s
#   [[ $VERBOSE = NO ]] || silent=
#   echo make $silent -j -C $path install
#   make $silent -j -C $path install
# }

# function stage_prerun() {
#   local stage_path=$work_path/stage
#   rm -fr $stage_path
#   mkdir -p $stage_path/{bin,db,dbd,ioc,log,autosave,opi}
# }

# function stage() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not stage
#     return 1
#   fi

#   local stage_path=$work_path/stage
#   local group=$(cfg_group $1)
#   if [[ $group == bases ]]; then
#     cp -a $path/db/* $stage_path/db
#     cp -a $path/bin/$host_arch/{caput,caget,camonitor,caRepeater} $stage_path/bin
#   elif [[ $group == modules ]]; then
#     if [[ -d $path/db ]]; then
#       cp -a $path/db/* $stage_path/db
#     fi
#     local bin_file=
#     for bin_file in $(cfg_bins $1); do
#       cp -a $path/bin/$host_arch/$bin_file $stage_path/bin
#     done
#   elif [[ $group == support ]]; then
#     local bin_file=
#     for bin_file in $(cfg_bins $1); do
#       cp -a $path/bin/$bin_file $stage_path/bin
#     done
#   elif [[ $group == iocs ]]; then
#     cp -a $path/bin/$host_arch/$(pkg_app_name $1) $stage_path/bin
#     cp -a $path/dbd/$(pkg_app_name $1).dbd $stage_path/dbd
#     if [[ -d $path/db ]]; then
#       cp -a $path/db/* $stage_path/db
#     fi
#     cp -a $path/iocBoot/$1/* $stage_path/ioc
#     cp -a $bin_path/start_ioc.sh $stage_path
#     chmod +x $stage_path/start_ioc.sh
#   fi

#   local opi_path=$stage_path/opi
#   local opi=$(cfg_opi $1)
#   if [[ -n $opi ]]; then
#     if [[ ! -d $opi_path/$1 ]]; then
#       cp -a $path/$opi $opi_path/$1
#     fi
#   fi
# }

# function stage_postrun() {
#   local opi_path=$work_path/stage/opi
#   if [[ ! -d $opi_path ]]; then
#     echo path $opi_path does NOT exists, can not do post stage
#     return 1
#   fi
#   cat << EOF > $opi_path/.project
# <?xml version="1.0" encoding="UTF-8"?>
# <projectDescription>
#   <name>$1</name>
#   <comment></comment>
#   <projects></projects>
#   <buildSpec></buildSpec>
#   <natures></natures>
#   <linkedResources>
# EOF
#   pushd $opi_path >/dev/null
#   local folders=$(find . -mindepth 1 -maxdepth 1 -type d)
#   for folder in $folders; do
#     cat << EOF >> $opi_path/.project
#     <link>
#       <name>$folder</name>
#       <type>2</type>
#       <location>PROJECT_LOC/$folder</location>
#     </link>
# EOF
#   done
#   popd >/dev/null
#   cat << EOF >> $opi_path/.project
#   </linkedResources>
# </projectDescription>
# EOF
# }

# function clean() {
#   local path=$(pkg_path $1)
#   if [[ ! -d $path ]]; then
#     echo package $1 path $path does NOT exists, can not clean
#     return 1
#   fi

#   echo make -C $path clean
#   make -C $path clean
# }

# function pack() {
#   local stage_path=$work_path/stage
#   if [[ ! -d $stage_path ]]; then
#     echo stage path $stage_path does NOT exists, can not pack
#     return 1
#   fi

#   # from https://makeself.io/
#   $bin_path/makeself.sh \
#     --bzip2 \
#     --nooverwrite \
#     --tar-quietly \
#     $stage_path \
#     $1.sh \
#     "BDEE recipe archive $1" \
#     echo "DONE!"
# }

# function upload() {
#   local archive_file=$1.sh
#   if [[ ! -f $archive_file ]]; then
#     echo archive $archive_file does NOT exists, can not upload
#     return 1
#   fi

#   local location=
#   if [[ $2 = YES ]]; then
#     location=$production_location
#   else
#     location=$devel_location
#   fi
#   if [[ ! -d $location ]]; then
#     echo location $location does NOT exists, can not upload
#     return 1
#   fi
#   cp $archive_file $location
#   if [[ $2 = YES ]]; then
#     # make it read-only
#     chmod a-w $location/$archive_file
#   fi
#   echo updloaded $location/$archive_file
# }



##################################################################################

function dbg() { [[ -z $DEBUG ]] || echo -e "[DBG] $@ (${FUNCNAME[1]}:${BASH_LINENO[0]})" >&2; }
function inf() { echo -e "[INF] ${@} (${FUNCNAME[1]}:${BASH_LINENO[0]})" >&2; }
function err() { echo -e "\n[ERR] ${@} (${FUNCNAME[1]}:${BASH_LINENO[0]})\n" >&2; }

function opt() {
  [[ -n $1 ]] || return 1
  local pos=
  for pos in "${ARGS[@]}"; do
    if [[ $pos = $1 ]]; then return 0; fi
  done
  return 1
}

# fun: cmd_init
# txt: this should be called at least once once, in an empty folder
#      to generate config files used with later commands
# opt: recipe: recipe uid to work with
function cmd_init() {
  # recipe uid to work with needs to come from CLI
  local recipe="${ARGS[0]}"
  if [[ -z $recipe ]]; then
    err missing recipe argument
    return 1
  fi

  # get the recipe uids from all known recipes
  local chain=$(find_chain_name $recipe)
  if [[ -z $chain ]]; then
    err chain for recipe \'$recipe\' not found
    return 1
  fi
  local uids=$(find_chain $recipe)

  echo CMD INIT: $chain
  echo chain uids: $uids

  if $(opt '-f'); then
    echo removing existing config files..
    rm -f $recipe_config $release_config $site_config
  fi

  if [[ ! -f $recipe_config ]]; then
    echo "# created $(date) by $USER @ $(hostname)" > $recipe_config
    echo "# recipe $recipe" >> $recipe_config
    for uid in $uids; do
      echo "$recipe CHAIN $uid" >> $recipe_config
    done
    echo created $recipe_config ..
    # echo content:; cat $recipe_config
  else
    echo exists $recipe_config ..
  fi

  if [[ ! -f $release_config ]]; then
    echo "# created $(date) by $USER @ $(hostname)" > $release_config
    echo "# recipe $recipe" >> $release_config
    for uid in $(load_chain); do
      local name=$(pkg_name $uid)
      local path=$(pkg_path $name)
      local name_upper=$(pkg_name_variable $name)
      echo "$name_upper=$path" >> $release_config
    done
    echo created $release_config ..
    # echo content:; cat $release_config
  else
    echo exists $release_config ..
  fi

  if [[ ! -f $site_config ]]; then
    echo "# created $(date) by $USER @ $(hostname)" > $site_config
    cat $share_path/CONFIG_SITE.local >> $site_config
    echo created $site_config ..
    # echo content:; cat $site_config
  else
    echo exists $site_config ..
  fi
}

# fun: cmd_prepare
# txt: prepares the packages for use with build et. al. commands:
#      * perform GIT clone, checkout
#      * adjust RELEASE and CONFIG_SITE files for EPICS packages
#      * call autogen.sh and configure for autotools based packages
#        to generate Makefile
function cmd_prepare() {
  local chain=$(load_chain_name)
  local uids=$(load_chain)
  echo CMD PREPARE: $chain
  echo chain uids: $uids

  local opi_path=$work_path/opi
  local css_project=$opi_path/project.xml
  local css_dot_project=$opi_path/.project
  if [[ ! -d $opi_path ]]; then
    mkdir -p $opi_path
  fi

  ## create CSS project file header if .project is missing
  if [[ ! -f $css_dot_project ]]; then
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $css_project
    echo '<projectDescription>' >> $css_project
    echo '<name>'$chain' (DEV)</name>' >> $css_project
    echo '  <comment></comment>' >> $css_project
    echo '  <projects></projects>' >> $css_project
    echo '  <buildSpec></buildSpec>' >> $css_project
    echo '  <natures></natures>' >> $css_project
    echo '  <linkedResources>' >> $css_project
  fi

  local uid=
  for uid in $uids
  do
    echo .. package $uid
    local name=$(pkg_name $uid)
    local version=$(pkg_version $uid)
    local repo=$(cfg_repo $name)
    local path=$(pkg_path $name)
    local group=$(cfg_group $name)

    ## clone the GIT repository if required
    if [[ ! -d $path ]]; then
      echo ... git clone $repo $name
      git clone $repo $name || return 1
    else
      echo ... package $uid already cloned
    fi

    ## checkout the version if required
    if [[ -d $path ]]; then
      local state=$(git --git-dir $path/.git --work-tree $path branch)
      if [[ $state != "* $version" ]] && [[ $state != "* (HEAD detached at $version)" ]]; then
        echo ... git --git-dir $path/.git --work-tree $path checkout $version
        git --git-dir $path/.git --work-tree $path checkout $version || return 1
      else
        echo ... package $uid already at version $version
      fi
    else
      err ... package $uid $path does NOT exists
      return 1
    fi

    ## pull the sources if requested from CLI
    if $(opt '-p'); then
      echo git --git-dir $path/.git --work-tree $path pull
      git --git-dir $path/.git --work-tree $path pull || return 1
      echo ... package $uid pulled sourced at version $version
    fi

    ## link OPI folder into CSS project if folder exists
    local opi=$(cfg_opi $name)
    if [[ -n $opi ]]; then
      if [[ ! -h $opi_path/$name ]]; then
        ln -snf $path/$opi $opi_path/$name || return 1
        ## create CSS project link entry  if .project is missing
        if [[ ! -f $css_dot_project ]]; then
          echo '    <link>' >> $css_project
          echo '      <name>'$name'</name>' >> $css_project
          echo '      <type>2</type>' >> $css_project
          echo '      <location>PROJECT_LOC/'$name'</location>' >> $css_project
          echo '    </link>' >> $css_project
        fi
        echo ... package $uid OPI folder linked
      else
        echo ... package $uid OPI folder already linked
      fi
    else
      echo ... package $uid has no OPI folder
    fi

    ## config package depending on the group
    if [[ $group = bases ]]; then
      if [[ ! -f $path/configure/CONFIG_SITE.local ]]; then
        cp $share_path/BASE_CONFIG_SITE.local $path/configure/CONFIG_SITE.local || return 1
        echo ... package $uid created ./configure/CONFIG_SITE.local
      else
        echo ... package $uid already exists ./configure/CONFIG_SITE.local
      fi
    elif [[ $group = modules ]] || [[ $group = iocs ]]; then
      if ! $(grep -q '^# BDEE local' $path/configure/RELEASE); then
        echo ... package $uid  updating ./configure/RELEASE
        sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/RELEASE
        echo '# BDEE local RELEASE' >> $path/configure/RELEASE
        echo "include \$(TOP)/../RELEASE.local" >> $path/configure/RELEASE || return 1
      else
        echo ... package $uid already updated ./configure/RELEASE
      fi
      if ! $(grep -q '^# BDEE local' $path/configure/CONFIG_SITE); then
        echo ... package $uid updating ./configure/CONFIG_SITE
        sed -e '/^[^#]/ s/^#*/### /' -i $path/configure/CONFIG_SITE
        echo '# BDEE local CONFIG_SITE' >> $path/configure/CONFIG_SITE
        echo "include \$(TOP)/../CONFIG_SITE.local" >> $path/configure/CONFIG_SITE || return 1
      else
        echo ... package $uid already updated ./configure/CONFIG_SITE
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
          echo ... package $uid ./autogen.sh --prefix=$path $(cfg_config $name)
          ./autogen.sh --prefix=$path $(cfg_config $name) || return 1
          popd >/dev/null
        else
          echo ... package $uid ./autogen.sh NOT found
        fi
      fi
      if [[ ! -f $path/configure ]]; then
        # try to run autoreconf to generate configure script
        if [[ -f $path/configure.ac ]]; then
          pushd $path >/dev/null
          echo ... package $uid autoreconf -si
          autoreconf -si || return 1
          popd >/dev/null
        else
          echo ... package $uid configure.ac NOT found
        fi
      fi
      if [[ ! -f $path/Makefile ]]; then
        if [[ -f $path/configure ]]; then
          pushd $path >/dev/null
          echo ... package $uid ./configure --prefix=$path $(cfg_config $name)
          ./configure --prefix=$path $(cfg_config $name) || return 1
          popd >/dev/null
        else
          echo ... package $uid configure NOT found
        fi
      else
        echo ... package $uid already has Makefile
      fi
      if [[ ! -f $path/Makefile ]]; then
        err package $uid source does NOT have Makefile
      fi
    fi
  done

  ## create CSS project file footer if .project is missing
  if [[ ! -f $css_dot_project ]]; then
    echo '  </linkedResources>' >> $css_project
    echo '</projectDescription>' >> $css_project
    cp $css_project $css_dot_project
  fi

}

# fun: cmd_build
# txt: builds the packages
function cmd_build() {
  local chain=$(load_chain_name)
  local uids=$(load_chain)
  echo CMD BUILD: $chain
  echo chain uids: $uids

  local stage_path=$work_path/stage
  local opi_path=$stage_path/opi
  local css_project=$opi_path/project.xml
  local css_dot_project=$opi_path/.project

  # remove stage files, will be recreated in this function
  rm -fr $stage_path
  mkdir -p $stage_path/{bin,db,dbd,ioc,log,autosave,opi}

  ## create CSS project file header
  echo '<?xml version="1.0" encoding="UTF-8"?>' > $css_project
  echo '<projectDescription>' >> $css_project
  echo '<name>'$chain'</name>' >> $css_project
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
    echo
    echo .. package $uid

    local name=$(pkg_name $uid)
    local version=$(pkg_version $uid)
    local repo=$(cfg_repo $name)
    local path=$(pkg_path $name)
    local group=$(cfg_group $name)

    if [[ ! -d $path ]]; then
      err ... package $uid source does NOT exists
      return 1
    fi

    ## clean the package if required
    if $(opt '-c'); then
      if [[ $group = bases ]] || [[ $group = modules ]] || [[ $group = iocs ]]; then
        echo ... make $silent -C $path -i -k uninstall realclean distclean clean
        make $silent -C $path -i -k uninstall realclean distclean clean || true
        find $path -name O.* | xargs rm -fr || true
      elif [[ $group = support ]]; then
        echo ... make $silent -C $path -i -k clean
        make $silent -C $path -i -k clean || true
        # XXX can not do this, because the autogen.sh/configure would need to be re-ran!
        # rm -f $path/configure $path/Makefile
      fi
    fi

    ## build the package
    echo ... make $silent -j -C $path install
    make $silent -j -C $path install || return 1

    ## stage the package artifacts generated during the build
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

    ## stage OPI files
    local opi=$(cfg_opi $name)
    if [[ -n $opi ]]; then
      if [[ ! -d $opi_path/$name ]]; then
        cp -a $path/$opi $opi_path/$name || return 1
        ## create CSS project link entry
        echo '    <link>' >> $css_project
        echo '      <name>'$name'</name>' >> $css_project
        echo '      <type>2</type>' >> $css_project
        echo '      <location>PROJECT_LOC/'$name'</location>' >> $css_project
        echo '    </link>' >> $css_project
        echo ... package $uid OPI folder copied
      else
        echo ... package $uid OPI folder already copied
      fi
    else
      echo ... package $uid has no OPI folder
    fi

  done

  ## create CSS project file footer
  echo '  </linkedResources>' >> $css_project
  echo '</projectDescription>' >> $css_project
  cp $css_project $css_dot_project

}

# fun: cmd_status
# txt: show status of the packages
function cmd_status() {
  local chain=$(load_chain_name)
  local uids=$(load_chain)
  echo CMD BUILD: $chain
  echo chain uids: $uids

  local uid=
  for uid in $uids
  do
    echo
    echo .. package $uid

    local name=$(pkg_name $uid)
    local version=$(pkg_version $uid)
    local repo=$(cfg_repo $name)
    local path=$(pkg_path $name)
    local group=$(cfg_group $name)

    if [[ ! -d $path ]]; then
      err ... package $uid source does NOT exists
      return 1
    fi

    # perform git status on each package source
    echo git --git-dir $path/.git --work-tree $path status --short --branch --porcelain
    git --git-dir $path/.git --work-tree $path status --short --branch --porcelain || return 1

    # perform git diff on each package source if requested from CLI
    if $(opt '-d'); then
      echo git --git-dir $path/.git --work-tree $path diff
      git --git-dir $path/.git --work-tree $path diff || return 1
    fi
  done
}

# fun: cmd_release
# txt: create archive of the built and copy it to a distribution location
function cmd_release() {
  local chain=$(load_chain_name)
  local uids=$(load_chain)
  echo CMD BUILD: $chain
  echo chain uids: $uids

  local stage_path=$work_path/stage
  if [[ ! -d $stage_path ]]; then
    err ... recipe $chain stage does NOT exists
    return 1
  fi

  local archive_file=$chain.sh
  # from https://makeself.io/
  $bin_path/makeself.sh \
    --bzip2 \
    --nooverwrite \
    --tar-quietly \
    $stage_path \
    $archive_file \
    "BDEE recipe archive $chain" \
    echo "DONE!" || return 1

  if [[ ! -d $dist_location ]]; then
    echo destination $dist_location does NOT exists, can not upload
    return 1
  fi

  # remove the archive at destination if requested from CLI
  if $(opt '-r'); then
    rm -f $dist_location/$archive_file
  fi
  cp $archive_file $dist_location || return 1
  # make it read-only
  chmod a-w $dist_location/$archive_file || return 1
  echo updloaded $dist_location/$archive_file
}

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
  # echo
  echo " > prepare            prepare the recipe for building"
  echo "     -p               perform git pull after config"
  # echo
  echo " > build              build the recipe"
  echo "     -c               perform clean before build"
  # echo
  echo " > status             show status of the recipe"
  echo "     -d               perform git diff"
  # echo
  echo " > release            pack artifacts and upload the archive"
  echo "     -r               remove the archive at destination folder"
  echo "     -l               destination folder"
  echo
  echo "tool version $bdee_version"
  echo
  # echo options:
  # echo "  -c              execute command on whole chain of packages (default no)"
  # echo "  -h              this text"
  # echo "  -p list         list of packages to work on (optional)"
  # echo "  -v              verbose command execution (default no)"
  # echo "  -P              upload to production (default devel)"
  # echo
}


###########################################################################
###########################        MAIN        ############################
###########################################################################

# CMD=
# RECIPE=
# PACKAGE_LIST=
# VERBOSE=NO
# UIDS=
# CHAIN=NO
# POSITIONAL=()
# PRODUCTION=NO

# while [[ $# -gt 0 ]]; do
# key="$1"
# case $key in
#   -h)
#   usage
#   exit 0
#   ;;
#   -c)
#   CHAIN=YES
#   shift # past argument
#   ;;
#   -p)
#   PACKAGE_LIST="$2"
#   shift # past argument
#   shift # past value
#   ;;
#   -v)
#   VERBOSE=YES
#   shift # past argument
#   ;;
#   -P)
#   PRODUCTION=YES
#   shift # past argument
#   ;;

#   *)    # unknown option
#   POSITIONAL+=("$1") # save it in an array for later
#   shift # past argument
#   ;;
# esac
# done

# if [[ ${#POSITIONAL[@]} -gt 1 ]]; then
#   CMD=${POSITIONAL[0]}
#   RECIPE=${POSITIONAL[1]}
#   # remove 0th and 1st element
#   unset POSITIONAL[0]
#   unset POSITIONAL[1]
# elif [[ ${#POSITIONAL[@]} -gt 0 ]]; then
#   CMD=${POSITIONAL[0]}
#   # remove 0th element
#   unset POSITIONAL[0]
# fi
# if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
#   POSITIONAL=( "${POSITIONAL[@]}" )
# else
#   POSITIONAL=()
# fi

# CLI arguments
#  - first is always command
#  - the rest are arguments to the command, handled in command context
[[ $# -gt 0 ]] || { usage; exit 1; }

CMD="$1"
shift
# ARGS="$@"
ARGS=("")
for i in "$@"; do
  ARGS+=("$i")
done

# VERBOSE=NO
# if $(opt '-v'); then
#   VERBOSE=YES
# fi

VERBOSE=
if $(opt '-V'); then
  VERBOSE=YES
fi
DEBUG=
if $(opt '-D'); then
  DEBUG=YES
fi

# echo BDEE $bdee_version
echo
# echo "POSITIONAL    = ${POSITIONAL[@]}"
# echo "CHAIN         = $CHAIN"
# echo "PACKAGE LIST  = $PACKAGE_LIST"
echo "CMD           = $CMD"
echo "ARGS          = ${ARGS[@]}"
echo "VERBOSE       = $VERBOSE"
echo "DEBUG         = $DEBUG"
# echo "RECIPE        = $RECIPE"
echo

# [[ -n $CMD ]] || { usage; exit 1; }
# [[ -n $RECIPE ]] || { usage; exit 1; }

if [[ $CMD = init ]]; then
  # cmd_init $RECIPE || exit 1
  cmd_init || exit 1
  echo SUCCESS
  exit 0
fi

if [[ $CMD = prepare ]]; then
  cmd_prepare || exit 1
  echo SUCCESS
  exit 0
fi

if [[ $CMD = build ]]; then
  cmd_build || exit 1
  echo SUCCESS
  exit 0
fi

if [[ $CMD = status ]]; then
  cmd_status || exit 1
  echo SUCCESS
  exit 0
fi

if [[ $CMD = release ]]; then
  cmd_release || exit 1
  echo SUCCESS
  exit 0
fi


echo
echo FAILED!!!!
echo
exit 22

# generate_meta $RECIPE
# generate_release_local $RECIPE
# generate_configsite_local $RECIPE

# # get list of uids from the recipe chain
# UIDS=$(cfg_chain $RECIPE)
# if [[ $CHAIN = NO ]]; then
#   # only act on last uid in the chain
#   UIDS=$(echo $UIDS | grep -o '[^ ]\+$')
# fi
# # reverse the uid list if required
# if [[ $CMD = clean ]]; then
#   UIDS=$(echo "$UIDS" | tac)
# fi
# echo UIDS: $UIDS

# # handle composite commands
# case $CMD in
#   prepare)    CMDS="clone checkout config" ;;
#   rebuild)    CMDS="pull build stage" ;;
#   provide)    CMDS="build stage" ;;
#   release)    CMDS="clone checkout config build stage pack upload" ;;
#   *)          CMDS="$CMD" ;;
# esac

# # execute command(s)
# for CMD in $CMDS; do

#   # commands that are ran on the recipe
#   if [[ $CMD = pack ]]; then
#       pack $RECIPE
#   elif [[ $CMD = upload ]]; then
#       upload $RECIPE $PRODUCTION
#   else

#     # commands that are ran on the recipe uids

#     # execute before handling uid(s)
#     case $CMD in
#       checkout)   checkout_prerun ;;
#       stage)      stage_prerun ;;
#       *) echo no prerun for command \'$CMD\'.. ;;
#     esac

#     for uid in $UIDS
#     do
#       name=$(pkg_name $uid)
#       version=$(pkg_version $uid)
#       echo

#       skip=
#       pkg_filter $name "$PACKAGE_LIST" || skip=1
#       if [[ -n $skip ]]; then
#         echo skipping package uid $uid
#         continue
#       fi

#       echo executing \'$CMD\' on uid $uid

#       case $CMD in
#         clone)      clone $name ;;
#         checkout)   checkout $name $version ;;
#         config)     config $name ;;
#         build)      build $name ;;
#         stage)      stage $name ;;
#         clean)      clean $name ;;
#         pull)       pull $name ;;
#         status)     status $name ;;
#         diff)       diff $name ;;

#         *) echo unknown command \'$CMD\', aborting!; exit 1 ;;
#       esac
#     done

#     # execute after handling uid(s)
#     case $CMD in
#       checkout)   checkout_postrun $RECIPE ;;
#       stage)      stage_postrun $RECIPE ;;
#       *) echo no postrun for command \'$CMD\'.. ;;
#     esac
#   fi
# done # for CMDS

# echo
# echo "success!"
# exit 0
