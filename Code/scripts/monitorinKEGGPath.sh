#!/bin/bash
echo "##################################"
echo "# Hi, Questo è il  servizio per  #"
echo "# monitorare l'avanzamento delle #"
echo "# pathway generate da KEGG       #"
echo "#                                #"
echo "#         by Bioinformatics Unit #"      
echo "##################################"
echo  ""
for exp in $(ls /home/utente/Desktop/research/RNA/output/) ; do
	not_DEGs=0
	if [[ -d /home/utente/Desktop/research/RNA/output/$exp/analysis/ ]]; then
                performed=$(find /home/utente/Desktop/research/RNA/output/$exp/analysis/*/Plot/KEGG_pathways/statistics.txt -print  | wc -l)
		total=$(ls /home/utente/Desktop/research/RNA/output/$exp/analysis | wc -l)
		#echo "$exp --> $performed/$total"
		for comparison in $(ls /home/utente/Desktop/research/RNA/output/$exp/analysis/)  ; do
			if [ $(head /home/utente/Desktop/research/RNA/output/$exp/analysis/$comparison/Tables/DEGs/DEGs.tsv | wc -l) -eq 1 ]; then
				not_DEGs=$((not_DEGs+1))
				#echo "$comparison"
			fi
		done
		echo "$exp --> $performed/$total ($not_DEGs confronti non presentano DEGs)"
	fi
done 



#read -p "Di quale vorresti monitorare i progressi?: " experiment
#performed=$(find /home/utente/Desktop/research/RNA/output/$experiment/analysis/*/Plot/KEGG_pathways/statistics.txt -print  | wc -l)
#total=$(ls /home/utente/Desktop/research/RNA/output/$experiment/analysis | wc -l)
#echo "Sono state generate le pathway per $performed su $total confronti per quanto riguarda l'esperiment o $experiment" 
