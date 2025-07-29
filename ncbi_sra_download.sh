#!/bin/bash

# ###########################################
#     NCBI SRA Download Script v2.2.0       #
#   CLI Output + Robust + Parallel + Safe   #
# ###########################################

# --- Strict Mode ---
# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# Pipestatus is the exit status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Default Configuration ---
CPU_THREAD_MAX=$(grep -c ^processor /proc/cpuinfo)
CPU_THREADS=$((CPU_THREAD_MAX / 4 > 0 ? CPU_THREAD_MAX / 4 : 1)) # Ensure at least 1
PARALLEL_JOBS=4
MEMORY="4G" # Use a more standard format for memory
CONDA_ENV_NAME="ncbi_sra_download"

# --- Functions ---
show_help() {
  cat << EOF
Usage: $0 <srr_list.txt> [OPTIONS]

Downloads and converts SRA files to compressed FASTQ in parallel.

Required:
  <srr_list.txt>    A file containing one SRR accession ID per line.

Options:
  --cores N         Number of CPU threads per conversion job (default: ${CPU_THREADS})
  --parallel N      Number of parallel downloads/conversions (default: ${PARALLEL_JOBS})
  --mem SIZE        Memory per conversion job, e.g., 8G, 4096M (default: ${MEMORY})
  --env NAME        Name of the Conda environment to use (default: ${CONDA_ENV_NAME})
  -h, --help        Show this help message and exit
EOF
}

# --- Argument Parsing (Robust Method) ---
# Use getopt for robust argument parsing
ARGS=$(getopt -o "h" --long "help,cores:,parallel:,mem:,env:" -n "$0" -- "$@")
if [ $? -ne 0 ]; then
    show_help
    exit 1
fi
eval set -- "$ARGS"

while true; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    --cores)   CPU_THREADS="$2"; shift 2 ;;
    --parallel)PARALLEL_JOBS="$2"; shift 2 ;;
    --mem)     MEMORY="$2"; shift 2 ;;
    --env)     CONDA_ENV_NAME="$2"; shift 2 ;;
    --)        shift; break ;; # Marks the end of options
    *)         echo "Internal error!"; exit 1 ;;
  esac
done

# Check for mandatory input file
LIST_FILE=$1
if [[ -z "$LIST_FILE" ]]; then
  echo "Error: No SRR list file provided." >&2
  show_help
  exit 1
fi

# --- Pre-run Checks ---
echo -e "NCBI SRA Download Script v3.1.0\n"

# Validate input file
if [ ! -f "$LIST_FILE" ]; then echo "Error: File not found: $LIST_FILE" >&2; exit 1; fi
if [ ! -s "$LIST_FILE" ]; then echo "Error: File is empty: $LIST_FILE" >&2; exit 1; fi
if [ ! -r "$LIST_FILE" ]; then echo "Error: File is not readable: $LIST_FILE" >&2; exit 1; fi

# Check for Conda and activate environment
if ! command -v conda &> /dev/null; then
  echo "Error: Conda not found. Please check your installation." >&2
  exit 1
fi
source "$(dirname "$(command -v conda)")/../bin/activate" "$CONDA_ENV_NAME"

# Check for required tools
for tool in prefetch fasterq-dump pigz pv; do
  if ! command -v $tool &> /dev/null; then
    echo "Error: Required tool '$tool' not found in environment '$CONDA_ENV_NAME'." >&2
    exit 1
  fi
done

# --- Setup ---
OUTDIR=$(dirname "$LIST_FILE")
LOGFILE="${OUTDIR}/sra_download.log"
FAILED_LOG="${OUTDIR}/sra_failed.log"
SUCCESS_LOG="${OUTDIR}/sra_success.log"
mkdir -p "$OUTDIR"
# Clear previous logs
> "$LOGFILE"
> "$FAILED_LOG"
> "$SUCCESS_LOG"

# Read, validate, and de-duplicate SRR list
readarray -t ALL_SRRS < <(grep -o 'SRR[0-9]\+' "$LIST_FILE" | sort -u)
if [ ${#ALL_SRRS[@]} -eq 0 ]; then
  echo "Error: No valid SRR IDs (e.g., SRR123456) found in $LIST_FILE." >&2
  exit 1
fi
TOTAL=${#ALL_SRRS[@]}

echo "--- Configuration ---"
echo "  Input list      : $LIST_FILE"
echo "  Output directory: $OUTDIR"
echo "  Threads/job     : $CPU_THREADS"
echo "  Parallel jobs   : $PARALLEL_JOBS"
echo "  Memory/job      : $MEMORY"
echo "  Total unique SRRs: $TOTAL"
echo "---------------------"
echo "Logging to: $LOGFILE"
echo "Starting processing..."

# --- Main Processing Function ---
process_srr() {
  local SRR=$1
  local INDEX=$2
  local TOTAL_COUNT=$3

  echo -e "\n\033[1;34m[$INDEX/$TOTAL_COUNT] Processing $SRR\033[0m"

  # Skip if already processed
  if [ -f "$OUTDIR/${SRR}_1.fastq.gz" ] || [ -f "$OUTDIR/${SRR}.fastq.gz" ]; then
    echo -e "\033[32m[$SRR] Already exists. Skipping.\033[0m"
    echo "$SRR" >> "$SUCCESS_LOG"
    return 0
  fi

  # Run prefetch
  echo "[$SRR] Downloading..."
  prefetch "$SRR" --output-directory "$OUTDIR" --max-size 100G

  # Run fasterq-dump
  echo "[$SRR] Converting to FASTQ..."
  fasterq-dump "$SRR" --outdir "$OUTDIR" --mem "$MEMORY" --split-files --threads "$CPU_THREADS" --progress

  # Compress FASTQ files
  for fq in "$OUTDIR"/${SRR}*.fastq; do
    if [ -s "$fq" ]; then
      echo "[$SRR] Compressing $fq..."
      pv "$fq" | pigz -p "$CPU_THREADS" > "${fq}.gz"
      rm "$fq"
    fi
  done

  local SRR_DIR="${OUTDIR}/${SRR}"
  if [ -d "$SRR_DIR" ]; then
      echo "[$SRR] Cleaning up intermediate directory..."
      rm -rf "$SRR_DIR"
  fi
  
  echo "$SRR" >> "$SUCCESS_LOG"
  echo -e "\033[32m[$SRR] Done.\033[0m"
}

# Export function and variables for parallel execution
export -f process_srr
export OUTDIR MEMORY CPU_THREADS SUCCESS_LOG

# --- Parallel Execution ---
CURRENT=0
process_wrapper() {
    local srr=$1
    CURRENT=$((CURRENT + 1))
    if process_srr "$srr" "$CURRENT" "$TOTAL"; then
        :
    else
        echo -e "\033[1;31m[$srr] FAILED. See log for error details.\033[0m"
        echo "$srr" >> "$FAILED_LOG"
    fi
}
export -f process_wrapper
export CURRENT TOTAL FAILED_LOG

# Pipe the validated list to xargs, sending output to both CLI and log file
printf "%s\n" "${ALL_SRRS[@]}" | xargs -P "$PARALLEL_JOBS" -I {} bash -c 'process_wrapper "{}"' 2>&1 | tee -a "$LOGFILE"

# --- Final Summary ---
SUCCESS_COUNT=$(wc -l < "$SUCCESS_LOG")
FAILED_COUNT=$(wc -l < "$FAILED_LOG")

echo -e "\n--- All Done ---"
echo "  ✅ Successful: $SUCCESS_COUNT"
if [ "$FAILED_COUNT" -gt 0 ]; then
  echo "  ❌ Failed: $FAILED_COUNT. See details in: $FAILED_LOG"
else
  echo "  ❌ Failed: 0"
fi
echo "  A complete log is in: $LOGFILE"
echo "------------------"