#!/bin/bash

while getopts n: option
do 
    case "${option}"
        in
	n)basespace_project_name=${OPTARG};;
    esac
done

basespace_path=$HOME/resources/basespace
basespace_auth_config=$HOME/.basespace/default.cfg
input_path=$HOME/Desktop/research/RNA/input/
if [[ ! -f $basespace_auth_config ]]; then
	$basespace_path auth --force --api-server https://api.euc1.sh.basespace.illumina.com
else
	echo "BaseSpace already authenticated"
fi

is_project=-1
while [ $is_project -ne 0 ]; do
	if [ ${#basespace_project_name} -eq 0 ]; then
		$basespace_path list project
		read -p "Write the project name: " basespace_project_name
	fi
	$basespace_path download project --name $basespace_project_name -o $input_path/$basespace_project_name/ --extension=fastq.gz
	is_project=$?
	if [ ! $is_project -eq 0 ]; then
		clear
		basespace_project_name=""
		echo "-----> Project name is not corrected <-----"
	fi
done

echo $basespace_project_name downloaded
echo Prepare fastq in correct folder

rm $input_path/$basespace_project_name/${basespace_project_name}*.json
for sample in $(ls $input_path/$basespace_project_name/); do
	mv $input_path/$basespace_project_name/$sample/* $input_path/$basespace_project_name/
	rm -r $input_path/$basespace_project_name/$sample
done
