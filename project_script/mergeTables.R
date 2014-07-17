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

getReadCnt <- function(file.name){
	reads.cnt <- read.table(file.name, header=TRUE, sep="\t", stringsAsFactors=FALSE, comment.char="")
	row.names(reads.cnt) <- reads.cnt[, "name"]
	reads.cnt.new <- reads.cnt[,c("name", "readCount")]
	sample.name <- dirname(file.name)
	colnames(reads.cnt.new) <- c("name", sample.name)
	reads.cnt.new
}

for (i in 1:length(tags)){
	file.pattern <- file.patterns[i]
	tag <- tags[i]
	reads.cnt.files <- list.files(path=".", pattern=file.pattern, recursive=TRUE, include.dirs=TRUE)
	reads.cnt.list <- lapply(reads.cnt.files, getReadCnt)
	names(reads.cnt.list) <- sapply(reads.cnt.files, dirname)
	reads.cnt.tbl <- join_all(reads.cnt.list, "name")
	reads.cnt.tbl[is.na(reads.cnt.tbl)] <- 0
	rownames(reads.cnt.tbl) <- reads.cnt.tbl[ ,1]
	reads.cnt.tbl <- reads.cnt.tbl[ , -1]
	write.table(reads.cnt.tbl, file=paste0(tag, "_counts.txt"), sep="\t", row.names=TRUE, quote=FALSE)
}