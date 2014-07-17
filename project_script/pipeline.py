import os
import sys
import yaml
from ruffus import *
import glob
import subprocess
import string

def expandOsPath(path):
    """
    To expand the path with shell variables.
    Arguments:
    - `path`: path string
    """
    return os.path.expanduser(os.path.expandvars(path))

def genFilesWithPattern(pathList, Pattern):
    """
    To generate rmdup Bam files list on the fly.
    Arguments:
    - `pathList`: the path of the files
    - `Pattern`: pattern like config["input_files"]
    """
    pathList.append(Pattern)
    Files = expandOsPath(os.path.join(*pathList))
    return Files

config_name = sys.argv[1]
config_f = open(config_name, "r")
config = yaml.load(config_f)
config_f.close()
inputfiles = expandOsPath(os.path.join(config["project_dir"], config["data_dir"], "fastq", config["input_files"]))
FqFiles = [x for x in glob.glob(inputfiles) if "_trimmed.fastq" not in x]

@transform(FqFiles, suffix(".fastq"), "_trimmed.fastq", config)
def cutAdapter(FqFileName, OutputFqFileName, config):
    """
    To cut adapter in 3'.
    Arguments:
    - `FqFileName`: file to be processed
    """
    cmds = ['cutadapter_miRNA.sh']
    cmds.append(config['adapter'])
    cmds.append(FqFileName)
    cmds.append(OutputFqFileName)
    logfile = FqFileName + ".cutAdapter.log"
    p = subprocess.Popen(
        cmds, stdout=open(logfile, "w"), stderr=open(logfile, "w"),
        bufsize=1)
    stdout, stderr = p.communicate()
    return stdout

@follows(cutAdapter, mkdir(expandOsPath(os.path.join(config["project_dir"], config["data_dir"], "FastQC"))))
@transform(cutAdapter, suffix("_trimmed.fastq"), ".fastqc.log", config)
def runFastqc(FqFileName, fastqcZip, config):
    """
    To run FastQC
    Arguments:
    - `FqFileName`: trimmed fastq file
    - `config`: config
    """
    cmds = ['fastqc']
    cmds.append("-o")
    cmds.append(expandOsPath(os.path.join(config["project_dir"], config["data_dir"], "FastQC")))
    if "fastqc_threads" in config:
        cmds.append("-t")
        cmds.append(str(config["fastqc_threads"]))
    else:
        cmds.append("-t")
        cmds.append("2")
    cmds.append(FqFileName)
    logfile = string.replace(FqFileName, "_trimmed.fastq", ".fastqc.log")
    p = subprocess.Popen(
        cmds, stdout=open(logfile, "w"), stderr=open(logfile, "w"),
        bufsize=1)
    stdout, stderr = p.communicate()
    return stdout

@follows(cutAdapter, mkdir(expandOsPath(os.path.join(config["project_dir"], config["output_dir"]))))
@transform(cutAdapter, suffix("_trimmed.fastq"), "_rc.log", config)
def runGroupReads(FqFileName, rcLog, config):
    """
    To run groupreads.pl to get read counts table.
    Arguments:
    - `FqFileName`: trimmed fastq file
    - `config`: config
    """
    baseName = os.path.basename(FqFileName)
    rcFile = string.replace(baseName, "_trimmed.fastq", ".rc")
    cmds = ['groupReads.pl']
    cmds.append("input=" + FqFileName)
    target = expandOsPath(os.path.join(config["project_dir"], config["output_dir"], rcFile))
    cmds.append("output=" + target)
    logfile = string.replace(FqFileName, "_trimmed.fastq", "_rc.log")
    p = subprocess.Popen(
        cmds, stdout=open(logfile, "w"), stderr=open(logfile, "w"),
        bufsize=1)
    stdout, stderr = p.communicate()
    return stdout

output_dir = expandOsPath(os.path.join(config["project_dir"], config["output_dir"]))
rcFiles = genFilesWithPattern([output_dir], "*.rc")

@follows(runGroupReads, runFastqc)
@transform(rcFiles, suffix(".rc"), "_miRanalyzer.log", config)
def runMiRanalyzer(rcFileName, rcLog, config):
    """
    To run groupreads.pl to get read counts table.
    Arguments:
    - `rcFileName`: read counts file
    - `config`: config
    """
    baseName = string.replace(os.path.basename(rcFileName), ".rc", "")
    output_dir = expandOsPath(os.path.join(config["project_dir"], config["output_dir"], baseName))
    os.mkdir(output_dir)
    cmds = ['/usr/bin/java']
    cmds.append(config['java_Xmx'])
    cmds.append('-jar')
    cmds.append(config['miRanalyzer_path'])
    cmds.append('input=' + rcFileName)
    cmds.append('output=' + output_dir)
    cmds.append('dbPath=' + config['miRanalyzer_db_path'])
    cmds.append('species=' + config['bowtie_index'])
    cmds.append('speciesShort=' + config['miRanalyzer_speciesShort'])
    cmds.append('kingdom=animal')
    cmds.append('justKnown=true')
    cmds.append('bowtiePath=' + config['miRanalyzer_bowtiePath'])
    cmds.extend(config['miRanalyzer_translibs'])
    print(" ".join(cmds))
    logfile = string.replace(rcFileName, ".rc", "_miRanalyzer.log")
    p = subprocess.Popen(
        cmds, stdout=open(logfile, "w"), stderr=open(logfile, "w"),
        bufsize=1)
    stdout, stderr = p.communicate()
    return stdout

## Run to FastQC step
pipeline_run([runMiRanalyzer], multiprocess=config["cores"])

## Plot the pipeline flowchart
# pipeline_printout_graph("all_flowchart.png", "png", [runMiRanalyzer], pipeline_name="Preprocessing of miRNA")