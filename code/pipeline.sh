echo
echo
echo "*******************************************"
echo "*                                         *"
echo "* Welcome in NGS data analysis pipeline   *"
echo "*                                         *"
echo "*              Bests, Luigi Chiricosta :) *"
echo "*                                         *"
echo "*******************************************"
echo 
echo

checkError()
{
	date >> $log
	local_error=$1
	error=$error"-"$local_error
	echo $local_error | tee -a $log

	if [ $local_error -ne 0 ]; then
	        exit
	fi
}

while getopts s:o:f:r: option
do
    case "${option}"
        in
        s)species=${OPTARG};;
	o)output_path=${OPTARG};;
	f)inputs_R1=${OPTARG};;
	r)inputs_R2=${OPTARG};;
    esac
done

if [[ -z $species ]] || [[ -z $output_path ]] || [[ -z $inputs_R1 ]]; then
        echo "Use $0 -s {human/mouse} -o output_path -f fullpath/L001.R1.fastq.gz[,fullpath/L002.R1.fastq.gz] [-r fullpath/L001.R2.fastq.gz[,fullpath/L002.R2.fastq.gz]]"
        exit
fi

echo species: $species
echo output_path: $output_path
echo forwards: $inputs_R1
first_input_R1=$(cut -f1 -d',' <<< $inputs_R1)
echo first forward: $first_input_R1
echo reverses: $inputs_R2
first_input_R2=$(cut -f1 -d',' <<< $inputs_R2)
echo first reverse: $first_input_R2

echo "******************************"
date
echo "******************************"


main=/home/$USER
resources=$main/resources
genomes_resources=$resources/genomes
tools_resources=$resources/tools
STAR=$tools_resources/STAR/source/STAR
trimmomatic_path=$tools_resources/Trimmomatic
trimmomatic="java -jar $trimmomatic_path/dist/jar/trimmomatic*"

if [[ $species == "human" ]] || [[ $species == "mouse" ]]; then
	genome=$genomes_resources/$species
else
	echo "No genome available for species $species"
	exit
fi

cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
running_cores=$((cores-1))
if [ $running_cores -gt $cores ]; then
        running_cores=$cores
fi
#running_cores=15 #hack running_cores

#if [ $running_cores -gt 15 ]; then
#        running_cores=15
#fi
#ram=$(free -h | grep Mem | awk '{print $2}' | sed 's/G//g')
#running_ram=$(($ram / 10))0

echo Using $running_cores cores

first_R1_name=$(basename "$first_input_R1")
if [ ${#inputs_R2} -ne 0 ]; then
	R2_name=$(basename "$first_input_R2")
fi
experiment=$(echo $first_R1_name | cut -f1 -d '.' | cut -f1 -d '_')

#output=$main/Desktop/research/RNA/output/pipeline/$experiment
output=$output_path/$experiment
temporary_output=$output
output_exist=0
while [ -d $temporary_output ]; do
	output_exist=$(($output_exist+1))
	temporary_output=${output}_$output_exist
done
output=$temporary_output
log=$output/pipeline.log
mkdir -p $output
echo Output in: $output | tee -a $log

date | tee -a $log
if [ ${#inputs_R2} -ne 0 ]; then
        echo "*** PAIR END ***" | tee -a $log
else
        echo "*** SINGLE END ***" | tee -a $log
fi


#STAR_prefix=FinalSorted
STAR_prefix=""
STAR_output_name=Aligned.out
STAR_forward_prefix=Forward_
STAR_reverse_prefix=Reverse_

#taskID=$(/home/spliced/executeTaskStarting.sh)

echo "-> Created experiment $experiment <-" | tee -a $log

echo "-> FASTQC CONTROLL STEP <-" | tee -a $log
cmd="$tools_resources/FastQC/fastqc --threads $running_cores --outdir $output $first_input_R1"
echo $cmd | tee -a $log
eval $cmd | tee -a $log
first_R1_short_name=$(echo $first_R1_name | cut -f1 -d '.')
cmd="unzip $output/${first_R1_short_name}_fastqc.zip -d $output/"
echo $cmd | tee -a $log
eval $cmd | tee -a $log

cmd="grep -w FAIL $output/${first_R1_short_name}_fastqc/summary.txt"
echo $cmd | tee -a $log
eval $cmd | tee -a $log

cmd="grep -w 'Sequence length' $output/${first_R1_short_name}_fastqc/fastqc_data.txt | sed 's/Sequence length\t//g' | cut -f2 -d '-'"
echo $cmd | tee -a $log
reads_length=$(eval $cmd | tee -a $log)
echo Mean reads lenght is $reads_length
smallrna_threshold=75
if [ $reads_length -lt $smallrna_threshold ]; then
	echo Analyzing as smallRNA | tee -a $log
	MINLEN=18
	ILLUMINACLIP=$trimmomatic_path/adapters/custom/illumina_adapters_small_rna.fasta
else
	echo Analyzing as full RNA | tee -a $log
	MINLEN=36 #75
        ILLUMINACLIP=$trimmomatic_path/adapters/custom/illumina_adapters.fasta
fi
	

echo "-> TRIMMING STEP <-" | tee -a $log
for input_R1 in $(sed 's/,/ /g' <<< "$inputs_R1"); do
	echo Working on $input_R1
        R1_name=$(basename "$input_R1")
	input_R2=$(sed 's/_R1_/_R2_/g' <<< "$input_R1")
	LEADING=3 #20
	TRAILING=3 #20
	SLIDINGWINDOW=4:15
	extra_params="ILLUMINACLIP:$ILLUMINACLIP:2:30:10 LEADING:$LEADING TRAILING:$TRAILING" # SLIDINGWINDOW:$SLIDINGWINDOW"
	if [[ "$inputs_R2" == *"$input_R2"* ]]; then
		echo Paired End | tee -a $log
		R2_name=$(basename "$input_R2")
		#cmd="$trimmomatic PE -threads $running_cores -phred33 $input_R1 $input_R2 $output/${R1_name}_PAIRED_TRIM.fq $output/${R1_name}_UNPAIRED_TRIM.fq $output/${R2_name}_PAIRED_TRIM.fq $output/${R2_name}_UNPAIRED_TRIM.fq ILLUMINACLIP:$ILLUMINACLIP:2:30:10 LEADING:30 TRAILING:28 SLIDINGWINDOW:4:28 MINLEN:$MINLEN 2>&1 | tee -a $log"
		cmd="$trimmomatic PE -threads $running_cores -phred33 $input_R1 $input_R2 $output/${R1_name}_PAIRED_TRIM.fq $output/${R1_name}_UNPAIRED_TRIM.fq $output/${R2_name}_PAIRED_TRIM.fq $output/${R2_name}_UNPAIRED_TRIM.fq $extra_params MINLEN:$MINLEN 2>&1 | tee -a $log"
	else
		echo Single End | tee -a $log
		cmd="$trimmomatic SE -threads $running_cores -phred33 $input_R1 $output/${R1_name}_UNPAIRED_TRIM.fq $extra_params MINLEN:$MINLEN 2>&1 | tee -a $log"
	fi
	echo "$cmd"
	eval "$cmd"
	checkError $?
done

echo "-> ALIGNMENT STEP <-" | tee -a $log
forward_paired=$(ls $output | grep _PAIRED_TRIM.fq | grep _R1_ | sort | sed "s|^|${output}/|g" | tr '\n' ',' | sed 's/,$//g')
reverse_paired=$(ls $output | grep _PAIRED_TRIM.fq | grep _R2_ | sort | sed "s|^|${output}/|g" | tr '\n' ',' | sed 's/,$//g')
forward_unpaired=$(ls $output | grep _UNPAIRED_TRIM.fq | grep _R1_ | sort | sed "s|^|${output}/|g" | tr '\n' ',' | sed 's/,$//g')
reverse_unpaired=$(ls $output | grep _UNPAIRED_TRIM.fq | grep _R1_ | sort | sed "s|^|${output}/|g" | tr '\n' ',' | sed 's/,$//g')
running_cores_star=15

if [ $reads_length -lt $smallrna_threshold ]; then
	echo "Small RNA..." | tee -a $log
	gtf=$genome/gencode.*.primary_assembly.annotation.mirna.gtf
	#https://www.encodeproject.org/documents/b4ec4567-ac4e-4812-b2bd-e1d2df746966/@@download/attachment/ENCODE_miRNA-seq_STAR_parameters_v2.pdf
	cmd="$STAR --runThreadN $running_cores_star --genomeDir $genome --sjdbGTFfile $gtf --readFilesIn $forward_unpaired --outFileNamePrefix $output/$STAR_prefix --alignEndsType EndToEnd -- outFilterMismatchNmax 1 --outFilterMultimapScoreRange 0 --quantMode TranscriptomeSAM --outReadsUnmapped Fastx --outSAMtype BAM SortedByCoordinate --outFilterMultimapNmax 10 --outSAMunmapped Within --outFilterScoreMinOverLread 0 --outFilterMatchNminOverLread 0 --outFilterMatchNmin 16 --alignSJDBoverhangMin 1000 --alignIntronMax 1 --outWigType wiggle --outWigStrand Stranded --outWigNorm RPM"
#--twopassMode Basic
	echo "$cmd" | tee -a $log
	eval "$cmd" | tee -a $log
	checkError $?
	cmd="samtools index -@ $running_cores $output/${STAR_prefix}Aligned.sortedByCoord.out.bam"
	echo "$cmd" | tee -a $log
	eval "$cmd" | tee -a $log
	checkError $?
	bams=$output/${STAR_prefix}Aligned.sortedByCoord.out.bam
else
	gtf=$genome/gencode.*.primary_assembly.annotation.gtf
	if [ ! -z $forward_paired ] && [ ! -z $reverse_paired ]; then
		echo "-> PAIRED ALIGNMENT <-" | tee -a $log
		cmd="$STAR --runThreadN $running_cores_star --genomeDir $genome --sjdbGTFfile $gtf --readFilesIn $forward_paired $reverse_paired --outFileNamePrefix $output/$STAR_prefix --outFilterIntronMotifs RemoveNoncanonical --outSAMtype BAM SortedByCoordinate --outReadsUnmapped Fastx --quantMode GeneCounts 2>&1 | tee -a $log"
		echo "$cmd" | tee -a $log
		eval "$cmd" | tee -a $log
		checkError $?
		cmd="samtools index -@ $running_cores $output/${STAR_prefix}Aligned.sortedByCoord.out.bam"
		echo "$cmd" | tee -a $log
		eval "$cmd" | tee -a $log
		checkError $?
		bams="$output/${STAR_prefix}Aligned.sortedByCoord.out.bam "
	else
		echo "Paired not performed" | tee -a $log
	fi
	#the following condition is performed only in forward mode sequencing
	if [ ! -z $forward_unpaired ] && [ -z $reverse_paired ]; then
		echo "-> FORWARD ALIGNMENT <-" | tee -a $log
		cmd="$STAR --runThreadN $running_cores_star --genomeDir $genome --sjdbGTFfile $gtf --readFilesIn $forward_unpaired --outFileNamePrefix $output/${STAR_prefix}$STAR_forward_prefix --outFilterIntronMotifs RemoveNoncanonical --outSAMtype BAM SortedByCoordinate --outReadsUnmapped Fastx --quantMode GeneCounts 2>&1 | tee -a $log"
		echo "$cmd" | tee -a $log
		eval "$cmd" | tee -a $log
		checkError $?
		cmd="samtools index -@ $running_cores $output/${STAR_prefix}${STAR_forward_prefix}Aligned.sortedByCoord.out.bam"
		echo "$cmd" | tee -a $log
		eval "$cmd" | tee -a $log
		checkError $?
		bams=$bams"$output/${STAR_prefix}${STAR_forward_prefix}Aligned.sortedByCoord.out.bam "
	else
		echo "Forward not performed" | tee -a $log
	fi
	#the following condition is stopped
	if [ 0 -eq 1 ] && [ ! -z $reverse_paired ]; then
		echo "-> REVERSE ALIGNMENT <-" | tee -a $log
		cmd="$STAR --runThreadN $running_cores_star --genomeDir $genome --sjdbGTFfile $gtf --readFilesIn $reverse_paired --outFileNamePrefix $output/${STAR_prefix}${STAR_reverse_prefix} --outFilterIntronMotifs RemoveNoncanonical --outSAMtype BAM SortedByCoordinate --outReadsUnmapped Fastx --quantMode GeneCounts 2>&1 | tee -a $log"
		echo "$cmd" | tee -a $log
		eval "$cmd" | tee -a $log
		checkError $?
		cmd="samtools index -@ $running_cores $output/${STAR_prefix}${STAR_reverse_prefix}Aligned.sortedByCoord.out.bam"
		echo "$cmd" | tee -a $log
		eval "$cmd" | tee -a $log
		checkError $?
		bams=$bams"$output/${STAR_prefix}${STAR_reverse_prefix}Aligned.sortedByCoord.out.bam"
	else
		echo "Reverse not performed" | tee -a $log
	fi
fi

echo "-> COMPUTE FINAL BAM <- "
finalBamOutput=$output/FinalAligned.sortedByCoord.out.bam
finalSortedBamOutput=$finalBamOutput #$output/FinalSortedAligned.sortedByCoord.out.bam
cmd="samtools merge -@ $running_cores $finalBamOutput $bams"
echo "$cmd" | tee -a $log
eval "$cmd" | tee -a $log
checkError $?
samtools index $finalBamOutput
cmd="samtools sort -@ $running_cores -O bam -o $finalSortedBamOutput $finalBamOutput"
echo "$cmd" | tee -a $log
#eval "$cmd" | tee -a $log
#checkError $?
#samtools index -@ $running_cores $finalSortedBamOutput

echo "-> COMPUTING DEPTH <-" | tee -a $log
#In the next line, $3 should be the third column of samtools but it is intendeed as the third parameter of the running script
cmd="samtools depth $finalSortedBamOutput -b $(ls $gtf) | awk '{sum=sum+$3; if($3==0){zeros=zeros+1}}END{if(NR==0) print \"BAM error\"; else print \"depth:\", sum/NR; print \"zero areas:\", zeros}' 2>&1 | tee -a $log"
echo "$cmd" | tee -a $log
#eval "$cmd"
checkError $?

echo "-> COUNTING READS <-" | tee -a $log
#for gtf in $(ls $genome/*.gtf); do
	cmd="htseq-count -s reverse -i gene_name -n $running_cores -f bam $finalSortedBamOutput $gtf | tee -a $log > $output/Aligned.count.$(basename $gtf).txt"
	echo "$cmd" | tee -a $log
	eval "$cmd" | tee -a $log
	checkError $?
#done
#/home/spliced/executeTaskEnding.sh $taskID $error

date | tee -a $log

echo Releasing lock | tee -a $log
rm -f /tmp/${experiment}.lock.pipeline | tee -a $log
