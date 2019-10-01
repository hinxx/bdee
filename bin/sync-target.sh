#!/bin/bash
#

if [[ $# -lt 2 ]]; then
	echo "usage: $(basename $0) user host|ip"
	exit 1
fi

user="$1"
host="$2"

data_folder=/data/bdee
local_folder=stage
remote_folder=${data_folder}/$(basename $(pwd))-stage

# ssh ${user}@${host} "{ echo foo; echo bar; exit 0; }"

echo copying the SSH public key to ${host} if required..
ssh-copy-id ${user}@${host} || exit 1

echo creating remote folders if required, root password may be required..
ssh -t ${user}@${host} "{
	if [[ ! -d ${data_folder} ]]; then
		sudo mkdir -p ${data_folder} || exit 1;
		sudo chown ${user}:${user} -R ${data_folder} || exit 1;
		echo created data ${data_folder};
	fi
	if [[ ! -d ${remote_folder} ]]; then
		mkdir -p ${remote_folder} || exit 1;
		echo created stage folder ${remote_folder};
	fi
	exit 0; }" || exit 1

# place contents of local stage folder into remote stage folder
rsync -avz ${local_folder}/ ${user}@${host}:${remote_folder} || exit 1

echo DONE!
exit 0
