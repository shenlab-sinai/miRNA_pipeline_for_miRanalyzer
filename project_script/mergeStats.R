#! /usr/bin/env Rscript

args <- commandArgs(TRUE)
config.file <- args[1]

# load the config yaml to read the config of the pipeline
library(yaml)
config <- yaml.load_file(config.file)

library(plyr)

# initilize the parameters
tags <- config[["stats_tags"]]
res.path <- paste0(config[["project_dir"]], "/", config[["output_dir"]])
setwd(res.path)
file.patterns <- config[["stats_files"]]

# initilaize the result data frame
total.reads.cnt <- as.data.frame(cbind(sample=NULL, tag=NULL, reads=NULL))

getTotalReadCnt.sub <- function(file.name, tag){
	reads.cnt <- read.table(file.name, header=TRUE, sep="\t", stringsAsFactors=FALSE, comment.char="")
	row.names(reads.cnt) <- reads.cnt[, "name"]
	reads.cnt.new <- reads.cnt[,c("name", "readCount")]
	sample.name <- dirname(file.name)
	row.line <- c(sample.name, tag, sum(reads.cnt$readCount))
}

for (i in 1:length(tags)){
	tag <- tags[i]
	file.pattern <- file.patterns[i]
	reads.cnt.files <- list.files(path=".", pattern=file.pattern, recursive=TRUE, include.dirs=TRUE)
	reads.cnt.list <- lapply(reads.cnt.files, getTotalReadCnt.sub, tag=tag)
	total.reads.cnt <- rbind(total.reads.cnt, do.call(rbind, reads.cnt.list))
}

tags <- c("total_reads_17_26nt")
file.patterns <- c("*.rc")
file.suffixes <- c(".rc")

getTotalReadCnt <- function(file.name, tag, file.suffix){
	reads.cnt <- read.table(file.name, header=FALSE, sep="\t", stringsAsFactors=FALSE, comment.char="")
	seq.len <- sapply(reads.cnt[,1], nchar)
	reads.cnt <- cbind(seq.len=seq.len, reads.cnt)
	new.reads.cnt <- reads.cnt[which(reads.cnt$seq.len<=26 & reads.cnt$seq.len >=17), ]
	total.cnt <- sum(new.reads.cnt$V2)
	sample.name <- gsub(file.suffix, "", file.name)
	row.line <- c(sample.name, tag, total.cnt)
}

for (i in 1:length(tags)){
	tag <- tags[i]
	file.pattern <- file.patterns[i]
	file.suffix <- file.suffixes[i]
	reads.cnt.files <- list.files(path=".", pattern=file.pattern)
	reads.cnt.list <- lapply(reads.cnt.files, getTotalReadCnt, tag=tag, file.suffix=file.suffix)
	total.reads.cnt <- rbind(total.reads.cnt, do.call(rbind, reads.cnt.list))
}

colnames(total.reads.cnt) <- c("sample", "type", "read_counts")
write.table(total.reads.cnt, file="stat_datasets_long_form.txt", sep="\t", row.names=FALSE, quote=FALSE)
total.reads.cnt.tbl <- reshape(total.reads.cnt, varying=NULL, timevar="type", idvar="sample", direction="wide")
write.table(total.reads.cnt.tbl, file="stat_datasets.txt", sep="\t", row.names=FALSE, quote=FALSE)