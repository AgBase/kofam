#! /bin/bash

#NEED TO ADD CPU OPTION FOR CMDLINE
#NEED TO ADD CHECK FOR KOFAM DB AND PULL IF NOT THERE (TOO BIG FOR CONTAINER)
#NEED TO REMOVE TMP DIRECTORY AFTER KOFAM RUNS?

# $1 KEGG species code (NA or related species code if species not in KEGG)
# $2 input file (protein FASTA without header lines)
# $3 output directory (must be existing directory at the moment)


# WORKS-TESTS WHETHER ACCESSIONS ARE NCBI PROTEIN IDS
acc1=$(head -n1 $2 | sed 's/>//g' | sed 's/\s.*$//')
if  [[ $acc1 == NP_* ]] || [[ $acc1 == XP_* ]] ;
then
	ncbi=true
	echo "$acc1 These are NCBI protein IDs."
else
	ncbi=false
fi


if [ "$ncbi" == true ] ;
then
	# WORKS-TAKES FASTA AND CREATES ACCESSION LIST. ACCESSION IS EVERYTHING BEFORE THE FIRST SPACE
	grep ">" $2 > $3/deflines.tmp
	sed -i 's/>//g' $3/deflines.tmp
	sed -i 's/\s.*$//' $3/deflines.tmp


	if grep -q $1 kegg_org_codes.txt;
	then
		#WORKS-PULL DATA
		echo "This is a KEGG species code. Pulling KEGG API DATA NOW."
		bash pull_data.sh $1 NA $3 ncbi

		#WORKS-MERGE DATA HERE
		echo "Creating annotations output."
		python merge_data.py "$1" no "$3" "$3" #need to remove indir from merge or add a variable for it here.

	else # ELSE MEANS THE THE CODE IS NOT A KEGG SPECIES CODE

		echo "This is not a KEGG species code. Running KofamScan now."
		#WORKS--RUN KOFAM HERE--MAY NEED TO PROVIDE A PATH FOR PROFILES ETC IN CONTAINER
#		../exec_annotation -o ./$3/kofam_result_full.txt -f detail --cpu 480 -p ../profiles/eukaryote.hal $2

		#WORKS-FILTER KOFAM HERE
		echo "Filtering KofamScan results"
		grep -P "^\*" $3/kofam_result_full.txt >> $3/kofam_filtered_asterisk.txt

		#WORKS-PULL DATA
		echo "Pulling KEGG API data."
		bash pull_data.sh $1 $3/kofam_filtered_asterisk.txt $3 ncbi

		#WORKS-MERGE DATA
		echo "Creating annotations output."
		python merge_data.py $1 yes $3 $3 #NEED TO REMOVE INDIR FROM MERGE_DATA OR ADD VARIABLE FOR IT HERE.
	fi

else #ELSE MEANS THESE ARE NOT NCBI PROTEIN IDS.
#FOR NON-NCBI ACCESSIONS WE WILL WILL NEED TO ADD STEP TO ID ORTHOLOGS/HOMOLOGS IF WE WANT TO ADD FLYBASE ANNOTATIONS (SEE MERGE DATA.PY).

	echo "These are NOT NCBI protein IDs. Proceeding with KofamScan."
	#RUN KOFAM HERE
#	../exec_annotation -o ./$3/kofam_result_full.txt -f detail --cpu 480 -p ../profiles/eukaryote.hal $2

	#FILTER KOFAM HERE
	echo "Filtering KofamScan results"
	grep -P "^\*" $3/kofam_result_full.txt >> $3/kofam_filtered_asterisk.txt

	if grep -q $1 kegg_org_codes.txt;
	then
		echo "This is a KEGG species". 

		#PULL DATA
		echo "Pulling KEGG API data."
		bash pull_data.sh $1 $3/kofam_filtered_asterisk.txt $3 non-ncbi


		#MERGE DATA
		python merge_data.py $1 yes $3 $3

	else #ELSE MEANS THIS IS NOT A KEGG SPECIES

		echo "This is not a KEGG species".

		#PULL DATA
		echo "Pulling KEGG API data."
		bash pull_data.sh $1 $3/kofam_filtered_asterisk.txt $3

		#MERGE DATA
		python merge_data.py $1 yes $3 $3
	fi
fi

if [ -f "$3"/link_ko_pathway.tsv ]; then rm "$3"/link_ko_pathway.tsv; fi
if [ -f "$3"/list_pathway.tsv ]; then rm "$3"/list_pathway.tsv; fi
if [ -f "$3"/conv_ncbi-proteinid_"$1".tsv ]; then rm "$3"/conv_ncbi-proteinid_"$1".tsv; fi
if [ -f "$3"/link_"$1"_ko.tsv ]; then rm "$3"/link_"$1"_ko.tsv; fi
if [ -f "$3"/link_pathway_"$1".tsv ]; then rm "$3"/link_pathway_"$1".tsv; fi
if [ -f "$3"/list_pathway_"$1".tsv ]; then rm "$3"/list_pathway_"$1".tsv; fi
if [ -f "$3"/deflines.tmp ]; then rm "$3"/deflines.tmp; fi
if [ -f "$3"/ko_ncbi.tsv ]; then rm "$3"/ko_ncbi.tsv; fi
if [ -f "$3"/Fbgn_CG.tsv ]; then rm "$3"/Fbgn_CG.tsv; fi
if [ -f "$3"/Fbgn_groupid.tsv ]; then "$3"/Fbgn_groupid.tsv; fi # CAN'T RM, PERMISSION DENIED--MAY NEED TO SET PERMISSIONS WHEN CREATING THE FILE
if [ -f "$3"/pathway_group_data_fb_2024_05.tsv ]; then 	rm "$3"/pathway_group_data_fb_2024_05.tsv; fi
if [ -f "$3"/pathway_group_data_fb_2024_05.tsv.gz ]; then rm "$3"/pathway_group_data_fb_2024_05.tsv.gz; fi
if [ -f "$3"/fbgn_annotation_ID_fb_2024_05.tsv ]; then 	rm "$3"/fbgn_annotation_ID_fb_2024_05.tsv; fi
if [ -f "$3"/fbgn_annotation_ID_fb_2024_05.tsv.gz ]; then  rm "$3"/fbgn_annotation_ID_fb_2024_05.tsv.gz; fi