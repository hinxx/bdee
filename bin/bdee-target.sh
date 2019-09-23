#!/bin/bash
#

server=http://bd-srv01.cslab.esss.lu.se
devel_path=bdee/devel
production_path=bdee/production

function download() {
  local archive_file=$1.sh
  if [[ -f $archive_file ]]; then
    echo archive $archive_file ALREADY exists, can not download
    return 1
  fi

  local remote_path=
  if [[ $2 = YES ]]; then
    remote_path=$server/$production_path/$archive_file
  else
    remote_path=$server/$devel_path/$archive_file
  fi
  echo downloading from $remote_path
  wget $remote_path
  chmod +x $archive_file
  ./$archive_file --info
}


###########################################################################
function usage() {
  echo
  echo $(basename $0) command recipe [-h] [-v] [-P]
  echo
  echo options:
  echo "  -h              this text"
  echo "  -v              verbose command execution (default no)"
  echo "  -P              download from production (default devel)"
  echo
}

CMD=
RECIPE=
VERBOSE=NO
POSITIONAL=()
PRODUCTION=NO

while [[ $# -gt 0 ]]; do
key="$1"
case $key in
  -h)
  usage
  exit 0
  ;;
  -v)
  VERBOSE=YES
  shift # past argument
  ;;
  -P)
  PRODUCTION=YES
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
echo "POSITIONAL    = ${POSITIONAL[@]}"

echo executing \'$CMD\' for recipe $RECIPE

case $CMD in
  download)   download $RECIPE ;;

  *) echo unknown command \'$CMD\', aborting!; exit 1 ;;
esac
