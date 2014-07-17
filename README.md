miRNA_pipeline_for_miRanalyzer
==============================

A pipeline of miRNA by using miRanalyzer

## Overview

Here is the pipeline I use to analyze miRNA-seq data by miRanalyzer.

![flowchart of the pipeline](https://raw.githubusercontent.com/ny-shao/miRNA_pipeline_for_miRanalyzer/master/all_flowchart.png "flowchart of the pipeline")

Now it support:
+ cut adapter
+ run FastQC as step of quality control
+ align sequences to annotation databases
+ predict novel miRNAs
+ summarize the results and generate the count table of the entries

## Requirement

+ [ruffus](http://www.ruffus.org.uk/)
+ [cutadapt](https://code.google.com/p/cutadapt/)
* [Bowtie](http://bowtie-bio.sourceforge.net/index.shtml)
* [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
+ The standalone version of [miRanalyzer](http://bioinfo5.ugr.es/miRanalyzer/miRanalyzer.php)
+ [plyr](http://cran.r-project.org/web/packages/plyr/index.html) An R package for data manipulation.

Install these softwares or packages and make sure the softwares are in `$PATH`.

## Installation

Put all script in `bin` folders to a place in `$PATH` or add these folders to `$PATH`.

## Usage

Firstly, you need to edit the `config.yaml` file to fit your need, then run:

```bash
nohup python pipline.py config.yaml &
```

For the organization of projects, I generally follow this paper: [A Quick Guide to Organizing Computational Biology Projects](http://www.ploscompbiol.org/article/info%3Adoi%2F10.1371%2Fjournal.pcbi.1000424). So `project_dir/data_dir/fastq` are the folder contains raw fastq files, while `project_dir/output_dir` folder are the results. The position of scripts in `project_script` doesn't matter at all. But I prefer to put them under project/script/miRanalyzer folder.

When the major part of the pipeline finishs, then run:

```bash
Rscript mergeStats.R config.yaml
Rscript mergeTables.R config.yaml
```
to summarize the final results. The items in `stats_tags` of `config.yaml` will be summarized.