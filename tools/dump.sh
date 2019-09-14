


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


###########################################################################
function usage() {
  echo
  echo $(basename $0) command recipe [-R list]
  echo
  echo options:
  # echo "  -n|--name arg      package name (see recipe INI files)"
  # echo "  -b|--build arg     package build (see recipe INI files)"
  # echo "  -u|--uid arg       package UID name:build (see recipe INI files)"
  # echo "  -f|--force         always perform command (default NO)"
  # echo "  -c|--chain         work on complete dependency chain (default NO)"
  # echo "  -d|--debug         debug mode (default NO)"
  # echo "  -t|--trace         trace mode (default NO)"
  # echo "  -v|--verbose       verbose mode (default NO)"
  echo "  -R list         list of packages to clean (optional)"
  echo
  # echo available commands:
  # echo "  "$CMDS
  # echo
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
key="$1"
case $key in
  # -f|--force)
  # FORCE=YES
  # shift # past argument
  # ;;
  # -c|--chain)
  # CHAIN=YES
  # shift # past argument
  # ;;
  # -d|--debug)
  # DEBUG=YES
  # shift # past argument
  # ;;
  # -t|--trace)
  # TRACE=YES
  # shift # past argument
  # ;;
  # -v|--verbose)
  # VERBOSE=YES
  # shift # past argument
  # ;;
  # -n|--name)
  # NAME="$2"
  # shift # past argument
  # shift # past value
  # ;;
  # -b|--build)
  # BUILD="$2"
  # shift # past argument
  # shift # past value
  # ;;
  # -u|--uid)
  # NAME="$(echo $2 | cut -d: -f1)"
  # BUILD="$(echo $2 | cut -d: -f2)"
  # shift # past argument
  # shift # past value
  # ;;
  -R)
  CLEAN_LIST="$2"
  shift # past argument
  shift # past value
  ;;

  *)    # unknown option
  POSITIONAL+=("$1") # save it in an array for later
  shift # past argument
  ;;
esac
done

