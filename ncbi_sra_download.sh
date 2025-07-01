#!/bin/bash

############################################
#     NCBI SRA Download Script v2.1.0      #
#     Parallel + Progress + Fail-safe      #
#         Hongjiang Liu, 06/30/25          #
############################################

echo -e "NCBI SRA Download Script v2.1.0 \n"

CPU_THREAD_MAX=$(grep -c ^processor /proc/cpuinfo)
CPU_THREAD=$((CPU_THREAD_MAX / 4))
PARALLEL_JOBS=4
MEM="4096MB"

show_help() {
  echo "Usage: $0 <srr_list.txt> [--cores N] [--parallel N] [--mem XMB]"
  echo
  echo "Options:"
  echo "  --cores N       Number of CPU threads per SRR process (default: 1/4 of total cores)"
  echo "  --parallel N    Number of parallel SRR downloads/conversions (default: 4)"
  echo "  --mem XMB       Memory per conversion in MB (default: 4096MB)"
  echo "  -h, --help      Show this help message and exit"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --cores)
      CPU_THREAD="$2"
      shift 2
      ;;
    --parallel)
      PARALLEL_JOBS="$2"
      shift 2
      ;;
    --mem)
      MEM="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      show_help
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"

# Input file
LIST=$1
OUTDIR=$(dirname "$LIST")
CONDA_ENV_NAME="ncbi_sra_download"

# Check if the input file is provided
if [[ -z "$LIST" ]]; then
  echo "Error: No SRR list file provided."
  show_help
  exit 1
fi

if [ ! -f "$LIST" ]; then echo "File not found: $LIST"; exit 1; fi
if [ ! -s "$LIST" ]; then echo "File is empty: $LIST"; exit 1; fi
if [ ! -r "$LIST" ]; then echo "File is not readable: $LIST"; exit 1; fi

# env
CONDA_PATH=$(command -v conda)
if [ -z "$CONDA_PATH" ]; then
  echo "ERROR: Conda not found. Please check your installation." >&2
  exit 1
fi
source $(dirname $(dirname "$CONDA_PATH"))/bin/activate ${CONDA_ENV_NAME}

# Check tool availability
for tool in sra-info prefetch fasterq-dump pigz pv; do
  if ! command -v $tool &> /dev/null; then
    echo "ERROR: $tool not found." >&2
    exit 1
  fi
done

echo "----------------------------------------"
echo "SRA Download Configuration:"
echo "  Input list     : $LIST"
echo "  Threads/core   : $CPU_THREAD"
echo "  Parallel jobs  : $PARALLEL_JOBS"
echo "  Memory per job : $MEM"
echo "----------------------------------------"

LOGFILE="${OUTDIR}/sra_download.log"
FAILED_LOG="${OUTDIR}/sra_failed.log"

mkdir -p "$OUTDIR"
> "$LOGFILE"
> "$FAILED_LOG"

TOTAL=$(wc -l < "$LIST")

echo "Output directory: $OUTDIR"
echo "Processing $TOTAL SRR entries..."
echo "Logging to $LOGFILE"

# Export variables for xargs
export OUTDIR LOGFILE FAILED_LOG CPU_THREAD TOTAL

process_srr() {
  INDEX=$1
  SRR=$2
  if [ -z "$SRR" ]; then
    echo -e "\033[33m[skip] Empty SRR ID.\033[0m" | tee -a "$LOGFILE"
    return
  fi
  if [[ ! "$SRR" =~ ^SRR[0-9]+$ ]]; then
    echo -e "\033[33m[skip] Invalid SRR ID format: $SRR\033[0m" | tee -a "$LOGFILE"
    return
  fi
  echo -e "\n\033[32m[$INDEX/$TOTAL] Processing $SRR\033[0m" | tee -a "$LOGFILE"

  if [ -f "$OUTDIR/${SRR}_1.fastq.gz" ] || [ -f "$OUTDIR/${SRR}.fastq.gz" ]; then
    echo -e "\033[32m[$SRR] Already processed. Skipping.\033[0m" | tee -a "$LOGFILE"
    return
  fi

  echo -e "\033[32m[$SRR] Downloading...\033[0m" | tee -a "$LOGFILE"
  prefetch "$SRR" --output-directory "$OUTDIR" --max-size 100G >> "$LOGFILE" 2>&1
  if [ $? -ne 0 ]; then echo "$SRR" >> "$FAILED_LOG"; return; fi

  echo -e "\033[32m[$SRR] Converting to FASTQ...\033[0m" | tee -a "$LOGFILE"
  fasterq-dump "$SRR" --outdir "$OUTDIR" --mem "$MEM" --split-files --progress --threads "$CPU_THREAD" >> "$LOGFILE" 2>&1
  if [ $? -ne 0 ]; then echo "$SRR" >> "$FAILED_LOG"; return; fi

  for fq in "$OUTDIR"/${SRR}_*.fastq; do
  if [ -f "$fq" ]; then
    echo -e "\033[32m[$SRR] Compressing $fq with progress...\033[0m" | tee -a "$LOGFILE"
    pv "$fq" | pigz -p "$CPU_THREAD" > "${fq}.gz" && rm "$fq"
  fi
done

  echo -e "\033[32m[$SRR] Done.\033[0m" | tee -a "$LOGFILE"
}

export -f process_srr

# Parallel processing
paste <(seq 1 "$TOTAL") "$LIST" | xargs -P "$PARALLEL_JOBS" -n 2 bash -c 'process_srr "$1" "$2"' _

# Clean up SRA dirs
echo "Cleaning temporary SRA directories..." | tee -a "$LOGFILE"
while read -r SRR; do
  [ -z "$SRR" ] && continue
  if [[ ! "$SRR" =~ ^SRR[0-9]+$ ]]; then
    echo "Skipping invalid SRR entry: '$SRR'" >> "$LOGFILE"
    continue
  fi
  SRR_DIR="${OUTDIR}/${SRR}"
  if [[ -d "$SRR_DIR" && "$SRR_DIR" =~ ^${OUTDIR}/SRR[0-9]+$ ]]; then
    rm -rf "$SRR_DIR"
    echo "Deleted $SRR_DIR" >> "$LOGFILE"
  else
    echo "Skip delete (not a valid SRR dir): $SRR_DIR" >> "$LOGFILE"
  fi
done < "$LIST"

echo -e "\nAll done!" | tee -a "$LOGFILE"
if [ -s "$FAILED_LOG" ]; then
  echo "Some SRRs failed. See: $FAILED_LOG"
fi