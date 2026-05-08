# NCBI SRA Download Script

A Bash script for downloading sequencing data from the NCBI SRA database, converting SRA accessions to FASTQ files, compressing the output, and cleaning up intermediate files.

## Features

* Batch download of SRA data from NCBI using a list of SRR accession numbers.
* SRR ID extraction, validation, sorting, and de-duplication from the input list.
* Parallel download and FASTQ conversion with `prefetch`, `fasterq-dump`, and `xargs`.
* FASTQ compression with `pigz`.
* Automatic cleanup of intermediate SRA folders.
* Success and failure tracking through separate log files.
* Adjustable CPU and memory usage per job.
* Timestamped, color-coded CLI status output with lock-protected message printing.
* Per-SRR job logs under a `logs/` directory.
* Automatically activates a conda environment with the required tools.
* Built-in `--help` system and input validation.

## Usage

```bash
NCBI SRA Download Script v2.3.0

Usage: ./ncbi_sra_download.sh [OPTIONS] <srr_list.txt>

Downloads and converts SRA files to compressed FASTQ in parallel.

Required:
  <srr_list.txt>    A file containing one SRR accession ID per line.

Options:
  --cores N         Number of CPU threads per conversion job (default: 1/4 of detected CPUs, minimum 1)
  --parallel N      Number of parallel downloads/conversions (default: 4)
  --mem SIZE        Memory per conversion job, e.g., 8G, 4096M (default: 4G)
  --env NAME        Name of the Conda environment to use (default: ncbi_sra_download)
  -h, --help        Show this help message and exit
```

### Example

```bash
# Download and convert SRR IDs listed in SRR_Acc_list.txt using default settings
./ncbi_sra_download.sh SRR_Acc_list.txt

# Download with custom settings: 8 cores, 2 parallel jobs, 8GB memory, and a specific conda environment
./ncbi_sra_download.sh --cores 8 --parallel 2 --mem 8G --env your_env_name SRR_Acc_list.txt
```

## Requirements

### Software

* Bash 4+ with `readarray`
* A GNU/Linux-style shell environment with `/proc/cpuinfo`, `getopt`, `flock`, `grep`, `sort`, and `xargs`
* [conda](https://docs.conda.io/en/latest/)
* [sra-tools](https://github.com/ncbi/sra-tools) (must include `fasterq-dump` and `prefetch`)
* [pigz](https://zlib.net/pigz/)

### Conda Environment

Example conda environment (`ncbi_sra_download`) configuration:

```bash
conda create -n ncbi_sra_download sra-tools pigz -c bioconda
```

## Output

* `.fastq.gz` files will be saved in the same directory as the input SRR list.
* Temporary `.sra` directories are automatically removed after conversion.
* `sra_download.log` captures the timestamped top-level status output.
* `logs/<SRR>.log` captures detailed `prefetch` and `fasterq-dump` output for each SRR.
* `sra_success.log` and `sra_failed.log` are reset at the start of each run and record completed or failed SRRs.
* `.sra_download.lock` is created in the output directory to coordinate parallel status messages.

## Notes

* Default settings use moderate CPU/memory. Customize with `--cores`, `--parallel`, and `--mem`.
* Existing `<SRR>_1.fastq.gz` or `<SRR>.fastq.gz` outputs are treated as already processed and logged as successful.
* Input files can contain extra text, but only `SRR` accessions matching `SRR[0-9]+` are processed.
* Runtime logs are overwritten at the start of each run.
* The script prints configuration at runtime.
* Must be executable:

  ```bash
  chmod +x ncbi_sra_download.sh
  ```

## Troubleshooting

* Check that conda and all required tools are available in your `PATH`.
* Run in a Linux, WSL, or compatible HPC shell environment; the current script reads CPU count from `/proc/cpuinfo` and uses `flock`.
* Use `--help` to check valid usage.

## License

MIT License

## Contact

For questions, issues, or contributions, please open an issue or pull request on GitHub.
