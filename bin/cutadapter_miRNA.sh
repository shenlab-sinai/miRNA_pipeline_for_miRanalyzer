#! /bin/env bash
## To cut adapter from miRNA fastq by cutadapter package.
## $1: 3' adapter
## $2: input fastq file
## $3: output fastq file
## default parameters: minium length of read: 16. minium quality score: 20. number of adapter to trim:2.

FILE=${2}
FILENAME=$(basename "$FILE")
FQDIR=$(dirname "$FILE")
EXT="${FILENAME##*.}"
FILENAME_BASE="${FILENAME%.*}"

case "$EXT" in
	fq | fastq | FQ | FASTQ ) cutadapt -m 16 -q 20 -n 2 -a ${1} ${2} > ${3}
	    ;;
	gz | GZ ) zcat ${2} | cutadapt -m 16 -q 20 -n 2 -a ${1} - > ${3}
	    ;;
esac
