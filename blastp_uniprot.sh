#!/bin/bash

#######################################################################################################
##SET UP OPTIONS FOR MAKEBLASTDB AND BLASTP

while getopts a:c:e:f:g:hk:l:m:o:pq:s:t: option
do
        case "${option}"
        in

                a) database=${OPTARG};;
                c) transcript_peps=${OPTARG};;
                f) max_matches=${OPTARG};;
                e) E_value=${OPTARG};;
                g) percID=${OPTARG};;
		m) perc_pos=${OPTARG};;
		o) out=${OPTARG};;
		s) bitscore=${OPTARG};;
                k) gapopen=${OPTARG};;
                l) gaps=${OPTARG};;
                q) qcovs=${OPTARG};;
		t) num_threads=${OPTARG};;
		h) help=true ;;
		p) pdef=true ;;
        esac
done
#####################################################################################################
if [[ "$help" = "true" ]] ; then
  echo "Options:
    -a Blast database basename ('uniprot_sprot' or 'uniprot_trembl')
    -c peptide fasta filename
    -o Blast output file basename
    [-e Expect value (E) for saving hits. Default is 10.]
    [-f Number of aligned sequences to keep. Default: 3]
    [-g Blast percent identity above which match should be kept. Default: keep all matches.]
    [-h help]
    [-m Blast percent positive identity above which match should be kept. Default: keep all matches.]
    [-s bitscore above which match should be kept. Default: keep all matches.]
    [-k Maximum number of gap openings allowed for match to be kept.Default: 100]
    [-l Maximum number of total gaps allowed for match to be kept. Default: 1000]
    [-q Minimum query coverage per subject for match to be kept. Default: keep all matches]
    [-t Number of threads.  Default: 8]
    [-p parse_deflines. Parse query and subject bar delimited sequence identifiers]" 
  exit 0
fi
#####################################################################################################

ARGS=''
database="${database}"
experimental="${experimental}"
transcript_peps="${transcript_peps}"
trans_peps=$(basename "${transcript_peps}")

num_threads=8
max_matches=3

#IF STATEMENTS EXIST FOR EACH OPTIONAL BLAST PARAMETER
if [ -n "${E_value}" ]; then ARGS="$ARGS -evalue $E_value"; fi
if [ -n "${max_matches}" ]; then ARGS="$ARGS -max_target_seqs $max_matches"; fi
if [ -n "${num_threads}" ]; then ARGS="$ARGS -num_threads $num_threads"; fi
if [[ "$pdef" = "true" ]]; then ARGS="$ARGS -parse_deflines"; fi
######################################################################################################

name="$database"
database='uniprot_database/'"$database"'.fa'
Dbase="$name"'.fa'

##MAKE BLAST INDEX
test -f "/uniprot_database/$Dbase.gz" && gunzip "/uniprot_database/$Dbase.gz"
test -f "./uniprot_database/$Dbase.gz" && gunzip "./uniprot_database/$Dbase.gz"

test -f "/uniprot_database/$Dbase" && makeblastdb -in /uniprot_database/$Dbase -dbtype prot -parse_seqids -out $name
test -f "uniprot_database/$Dbase" && makeblastdb -in uniprot_database/$Dbase -dbtype prot -parse_seqids -out $name
    
##RUN BLASTP
blastp  -query $transcript_peps -db $name -out $out.asn -outfmt 11 $ARGS


##MAKE BLAST OUTPUT FORMATS 1 AND 6
blast_formatter -archive $out.asn -out $out.html -outfmt 0 -html
blast_formatter -archive $out.asn -out $out.tsv -outfmt '6 qseqid qstart qend sseqid sstart send evalue pident qcovs ppos gapopen gaps bitscore score'
#################################################################################################################

##FILTER BALST OUTPUT 6 (OPTIONALLY) BY %ID, QUERY COVERAGE, % POSITIVE ID, BITSCORE, TOTAL GAPS, GAP OPENINGS
if [ -z "${perc_ID}" ]; then perc_ID="0"; fi
if [ -z "${qcovs}" ]; then qcovs="0"; fi
if [ -z "${perc_pos}" ]; then perc_pos="0"; fi
if [ -z "${bitscore}" ]; then bitscore="0"; fi
if [ -z "${gaps}" ]; then gaps="1000"; fi
if [ -z "${gapopen}" ]; then gapopen="100"; fi
awk -v x=$percID -v y=$qcovs -v z=$perc_pos -v w=$bitscore -v v=$gaps -v u=$gapopen '{ if(($8 > x) && ($9 > y) && ($10 > z) && ($13 > w) && ($12 < v) && ($11 < u)) { print }}' $out.tsv > tmp.tsv

##CALCULATE QUERY AND SUBJECT LENGTH COLUMNS AND ADD THEM TO OUTPUT 6
awk 'BEGIN { OFS = "\t" } {print $1, $3-$2, $2, $3, $4, $6-$5, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14}' tmp.tsv > tmp2.tsv

##APPEND HEADER LINE TO OUTPUT 6
echo -e "Query_ID\tQuery_length\tQuery_start\tQuery_end\tSubject_ID\tSubject_length\tSubject_start\tSubject_end\tE_value\tPercent_ID\tQuery_coverage\tPercent_positive_ID\tGap_openings\tTotal_gaps\tBitscore\tRaw_score" | cat - tmp2.tsv > temp && mv temp $out.tsv

##REMOVE FILES THAT ARE NO LONGER NECESSARY
if [ -s $out'.tsv' ]
then
    rm tmp.tsv
    rm tmp2.tsv
    rm *.phr
    rm *.pin
    rm *.pog
    rm *.psd
    rm *.psi
    rm *.psq
fi


