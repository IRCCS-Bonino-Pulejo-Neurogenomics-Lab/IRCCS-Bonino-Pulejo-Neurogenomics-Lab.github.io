#!/bin/bash

runs_argument_position=3
if [ $# -lt $runs_argument_position ]; then 
	echo "Use $0 {human/mouse} output_path fullpath/R1.fastq.gz,[fullpath/R2.fastq.gz] [fullpath/R1.fastq.gz,[]] [...]"
	exit
fi

echo

scripts=/home/$USER/Desktop/research/RNA/scripts

output_path=$2
echo "> Output: $output_path"
generalLog=$output_path/generalLog
groups_path=$output_path/Groups
analysis_path=$output_path/analysis
mkdir -p $groups_path

species=$1
echo "> Found species: $species" | tee -a $generalLog

echo "> Experiments found: " | tee -a $generalLog
for paramID in $(seq $runs_argument_position "$#"); do
        experiment=$(basename $(echo "$@" | cut -d ' ' -f $paramID | cut -d ',' -f1) | cut -f1 -d '.' | cut -f1 -d '_')
	echo $experiment | tee -a $generalLog
        mkdir -p $groups_path/$experiment
done

echo "Setting groups priority" | tee -a $generalLog
groups=$(ls $groups_path/ | sort)
groups_numeration=$(seq $(echo "$groups" | wc -l))
paste <(echo "$num") <(echo "$groups") -d '-'
read -p "List groups separated by comma (i.e. 1,2,3) or keep empty for no priority:\n> " groups_priority

for paramID in $(seq $runs_argument_position "$#"); do
	echo "------------"
	echo "> Elaborate run $paramID" | tee -a $generalLog
	run=$(echo "$@" | cut -d ' ' -f $paramID)
	forward=$(echo $run | cut -d ',' -f1) #$(basename $(echo $run | cut -d ',' -f1))
	reverse=$(echo $run | cut -d ',' -f2) #$(basename $(echo $run | cut -d ',' -f2))
	experiment=$(basename $(echo $forward) | cut -f1 -d '.' | cut -f1 -d '_')
	cmd="$scripts/pipeline.sh -s $species -o $output_path -f $forward -r $reverse 1>/dev/null"
	echo "$cmd" | tee -a $generalLog
	eval "$cmd" | tee -a $generalLog

	cp $output_path/$experiment/Aligned.count.*.txt $groups_path/$experiment/
done

echo "Generating R script..." | tee -a $generalLog
cmd="$scripts/generateRscript.sh -s $species -o $output_path -p $groups_priority"
#cmd="curl -X PATCH -d '{\"cmd\":\"'\"/home/spliced/generateRscript.sh $species $output_path\"'\"}' https://biolab-server-irccs.firebaseio.com/IRCCS/biolab.json &>/dev/null"
echo "$cmd" | tee -a $generalLog
eval "$cmd" | tee -a $generalLog

mkdir $analysis_path
