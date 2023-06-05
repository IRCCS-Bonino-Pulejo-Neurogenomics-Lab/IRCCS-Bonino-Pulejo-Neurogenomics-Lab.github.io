echo "Verifying analysis..." | tee -a $generalLog
for comparison in $(ls $analysis_path/); do
        echo $comparison;

        kegg=$(ls $analysis_path/$comparison/Tables/KEGG\ enrichment/kegg.enrichment.tsv)
        if [[ ! -f $kegg || $(du -h $kegg | cut -f1) == 0 ]]; then
                echo "KEGG enrichment does not exist";
        fi

        #go=$(ls $analysis_path/$comparison/Tables/GO\ enrichment/kegg.enrichment.tsv)
        #if [[ ! -f $kegg || $(du -h $kegg | cut -f1) == 0 ]]; then
        #        echo "KEGG enrichment does not exist"; 
        #fi
done

