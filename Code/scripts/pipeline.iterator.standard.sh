#!/bin/bash

rscript=1

while getopts i:o:s:p:e:r: option
do
    case "${option}"
        in
        i)project_input=${OPTARG};;
	o)project_output=${OPTARG};;
	e)extra_groups_paths=${OPTARG};;
        s)species=${OPTARG};;
	p)priority=${OPTARG};;
	r)rscript=${OPTARG};;
    esac
done

if [[ -z $project_input ]] || [[ -z $species ]]; then
        echo "Use $0 -s {human/mouse} -i project_input [-o project_output] [-p priority] [-e extra_group_path1,extra_group_path2,...][-r 0]"
	if [[ -z $project_input ]]; then
		echo Projects: 
		paste <(echo "$groups_numeration") <(echo "$groups") -d '-'
		echo "$(ls $HOME/Desktop/research/RNA/input/)"
	fi
        exit
fi

main_path=$HOME/Desktop/research/RNA
scripts=$main_path/scripts
input_path=$main_path/input/$project_input
if [[ ! -z $project_output ]]; then
	output_path=$project_output
else
        output_path=$main_path/output/$project_input
fi
generalLog=$output_path/generalLog
groups_path=$output_path/Groups
analysis_path=$output_path/analysis

mkdir -p $output_path
date | tee -a $generalLog

echo project input: $input_path | tee -a $generalLog
echo project output: $output_path | tee -a $generalLog
echo species: $species | tee -a $generalLog
echo log: $generalLog | tee -a $generalLog
echo groups path: $groups_path | tee -a $generalLog
echo analysis path: $analysis_path | tee -a $generalLog

experiments=$(ls $input_path | grep 'fastq.gz' | sed 's/_S[0-9]*_L00[1-4]_R[1-2]_001.fastq.gz//g' | sort | uniq)

echo "> Experiments found: " | tee -a $generalLog
echo $experiments | tee -a $generalLog
for experiment in $experiments; do
        mkdir -p $groups_path/$experiment
done

extra_experiments=0
if [[ ! -z $extra_groups_paths ]]; then
	for extra_group_path in $(echo $extra_groups_paths | sed 's/,/ /g'); do
		extra_experiments=$(($extra_experiments+1))
		echo "> Experiment extra found: $extra_group_path" | tee -a $generalLog
	        cp -r $extra_group_path $groups_path/
	done
fi
echo Extra experiments: $extra_experiments

echo 

echo "Setting groups priority" | tee -a $generalLog
if [[ -z $priority ]]; then
	groups=$(ls $groups_path/ | sort)
	groups_numeration=$(seq $(echo "$groups" | wc -l))
	default_priority=$(echo $groups_numeration | sed 's/ /,/g')
	paste <(echo "$groups_numeration") <(echo "$groups") -d '-'
	echo "List groups separated by comma (keep empty for default priority $default_priority):" 
	read -p ">" priority
	if [[ -z $priority ]]; then
		priority=$default_priority
	fi
fi
echo Priority: $priority | tee -a $generalLog

for experiment in $experiments; do 
	echo Current experiment: $experiment | tee -a $generalLog
	forward=$(ls $input_path | grep ^${experiment}_S[0-9]*_L[0-9]*_R1_001.fastq.gz | sort | sed "s|^|${input_path}/|g" | tr '\n' ',' | sed 's/,$//g')
	reverse=$(ls $input_path | grep ^${experiment}_S[0-9]*_L[0-9]*_R2_001.fastq.gz | sort | sed "s|^|${input_path}/|g" | tr '\n' ',' | sed 's/,$//g')

	echo Forward: $forward | tee -a $generalLog
	echo Reverse: $reverse | tee -a $generalLog
	cmd="$scripts/pipeline.sh -s $species -o $output_path -f $forward"
	if [ ${#reverse} -ne 0 ]; then
		cmd=$cmd" -r $reverse"
	fi
	echo "$cmd" | tee -a $generalLog
	eval "$cmd" | tee -a $generalLog
	
	#experiment=$(echo $run | cut -f1 -d '_')
	#mkdir -p $groups/$experiment
        cmd="cp $output_path/$experiment/Aligned.count.*.txt $groups_path/$experiment/Aligned.count.txt"
	echo "$cmd" | tee -a $generalLog
	eval "$cmd" | tee -a $generalLog
done

echo "Generating R script..." | tee -a $generalLog
cmd="$scripts/generateRscript.sh -o $output_path"
echo "$cmd" | tee -a $generalLog
eval "$cmd" | tee -a $generalLog

mkdir $analysis_path

cmd="Rscript $output_path/script.R $species $priority $output_path true true true true \"\" \"\""
echo "$cmd" | tee -a $generalLog

if [[ $rscript -eq 1 ]]; then
	eval "$cmd" | tee -a $generalLog
fi
