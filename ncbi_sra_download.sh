#!/bin/bash

############################################
#      NCBI SRA Download Script v1.0       #
#         Hongjiang Liu, 04/01/25          #
############################################
echo -e "NCBI SRA Download Script v1.0 \n"

# Input file
LIST=$1
OUTDIR=$(dirname "$LIST")
CONDA_ENV_NAME="ncbi_sra_download"

# Check if the input file is provided
if [ -z "$LIST" ]; then
  echo "Usage: $0 <srr_list.txt>"
  echo "This script downloads SRA files from NCBI and converts them to FASTQ format."
  exit 1
fi
# -h or --help
if [[ "$LIST" == "-h" || "$LIST" == "--help" ]]; then
  echo "Usage: $0 <srr_list.txt>"
  echo "This script downloads SRA files from NCBI and converts them to FASTQ format."
  exit 0
fi
# Check if the file exists
if [ ! -f "$LIST" ]; then
  echo "File not found: $LIST"
  exit 1
fi
# Check if the file is empty
if [ ! -s "$LIST" ]; then
  echo "File is empty: $LIST"
  exit 1
fi
# Check if the file is readable
if [ ! -r "$LIST" ]; then
  echo "File is not readable: $LIST"
  exit 1
fi

# env
CONDA_PATH=$(command -v conda)
if [ -z "$CONDA_PATH" ]; then
  echo "ERROR: Conda not found. Please check your installation." >&2
  exit 1
fi
source $(dirname $(dirname "$CONDA_PATH"))/bin/activate ${CONDA_ENV_NAME}

if [ ! "$(command -v sra-info)" ]; then
  echo "ERROR: SRA-tools not found." >&2
  exit 1
fi
# Check if fasterq-dump is available
if [ ! "$(command -v fasterq-dump)" ]; then
  echo "ERROR: fasterq-dump not found." >&2
  exit 1
fi
# Check if pigz is available
if [ ! "$(command -v pigz)" ]; then
  echo "ERROR: pigz not found." >&2
  exit 1
fi

CPU_THREAD_MAX=`grep 'processor' /proc/cpuinfo | sort -u | wc -l`
CPU_THREAD=`expr ${CPU_THREAD_MAX} \/ 4`

echo "Output directory: ${OUTDIR}"
# Download SRA files
cd ${OUTDIR}
cat ${LIST} | xargs -I {} prefetch {} --output-directory ${OUTDIR} --max-size 100G
echo "Download completed. Converting SRA files to FASTQ format..."
# Convert SRA files to FASTQ format
cat ${LIST} | xargs -I {} fasterq-dump {} --outdir ${OUTDIR} --mem 1024MB --split-files --progress --threads ${CPU_THREAD}
echo "Conversion completed. Compressing FASTQ files..."
# Compress FASTQ files
ls ${OUTDIR}/*.fastq | xargs -I {} pigz -p ${CPU_THREAD} {}
# Delete SRA folders
# cd ${OUTDIR}
find ${OUTDIR} -type d -name "SRR*" -exec rm -rf {} \;
echo "SRA folders deleted."
echo "All done!"