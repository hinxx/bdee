#!/bin/bash
#
#

this_path=$(realpath $(dirname $0))

if [[ $# -lt 1 ]]; then
  echo "Usage $(basename $0) <ioc_name>"
  exit 1
fi
ioc_name=$1

function envSet() {
  echo "epicsEnvSet(\"$1\",\"$2\")"
}

# generate envVars (similar to envPaths)
# envVars includes other environment variables than original envPaths does
# envVars does not define all the support module paths at all (all db files are in $(TOP_DIR)/db)
# envVars does not define $(TOP) to avoid warning message at IOC startup (starting the IOC from
# different path path; not build path)
function create_envVars () {
  cat << EOF > $ioc_path/envVars
# Generated on $(date)
$(envSet APP $app)
$(envSet IOC_NAME $ioc_name)
$(envSet TOP_DIR $this_path)
$(envSet IOC_DIR $this_path/ioc/$ioc_name)
$(envSet BIN_DIR $this_path/bin)
$(envSet DB_DIR $this_path/db)
$(envSet DBD_DIR $this_path/dbd)
$(envSet AUTOSAVE_DIR $this_path/autosave)
$(envSet EPICS_DB_INCLUDE_PATH $this_path/db)
$(envSet PATH $this_path/bin:\$PATH)
EOF
}

############################################################################

app_path=$(find $this_path/bin -name *App)
nr_apps=$(echo "$app_path" | wc -w)
if [[ $nr_apps -eq 0 ]]; then
  echo "ERROR: no application binary found in $this_path/bin"
  exit 1
fi
if [[ $nr_apps -ne 1 ]]; then
  echo "ERROR: more than 1 application binary found in $this_path/bin"
  exit 1
fi
echo "Using application binary $app_path"
app=$(basename $app_path)

ioc_path=$this_path/ioc/$1
if [[ ! -d $ioc_path ]]; then
  echo "ERROR: IOC folder $ioc_path not found"
  exit 1
fi
echo "Using IOC folder $ioc_path"

if [[ ! -f $ioc_path/st.cmd ]]; then
  echo "ERROR: IOC startup file $ioc_path/st.cmd not found"
  exit 1
fi
echo "Using IOC startup file $ioc_path/st.cmd"

# generate envVars file
create_envVars

if [[ ! -f $ioc_path/envVars ]]; then
  echo "ERROR: IOC environment file $ioc_path/envVars not found"
  exit 1
fi
echo "Using IOC environment $ioc_path/envVars"

# move to IOC folder and execute the application with main startup
# file as argument
cd $ioc_path && $app_path st.cmd

exit 0
