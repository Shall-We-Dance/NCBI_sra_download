# NCBI SRA Download Script

A Bash script for downloading sequencing data from the NCBI SRA database, converting `.sra` files to `.fastq`, compressing the output, and cleaning up intermediate files. This version adds parallel processing, progress bars, error handling, command-line configuration, and enhanced logging.

## Features

* Batch download of SRA data from NCBI using a list of SRR accession numbers.
* FASTQ conversion via `fasterq-dump` with progress monitoring.
* Parallel compression of FASTQ files with `pigz`.
* Automatic cleanup of intermediate SRA folders.
* Fail-safe mechanism that logs failed SRR downloads or conversions.
* Adjustable CPU and memory usage per job.
* Color-coded log output to indicate download, warning, and error statuses.
* Automatically activates a conda environment with the required tools.
* Built-in `--help` system and input validation.

## Usage

```bash
NCBI SRA Download Script v2.2.0

Usage: ncbi_sra_download.sh <srr_list.txt> [--cores N] [--parallel N] [--mem SIZE] [--env NAME] [-h|--help]

Downloads and converts SRA files to compressed FASTQ in parallel.

Required:
  <srr_list.txt>    A file containing one SRR accession ID per line.

Options:
  --cores N         Number of CPU threads per conversion job (default: max/4)
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
./ncbi_sra_download.sh SRR_Acc_list.txt --cores 8 --parallel 2 --mem 8G --env your_env_name
```

## Requirements

### Software

* [conda](https://docs.conda.io/en/latest/)
* [sra-tools](https://github.com/ncbi/sra-tools) (must include `fasterq-dump`, `sra-info`, `prefetch`)
* [pigz](https://zlib.net/pigz/)
* pv (for progress bar)

### Conda Environment

Example conda environment (`ncbi_sra_download`) configuration:

```bash
conda create -n ncbi_sra_download sra-tools pigz pv -c bioconda
```

## Output

* `.fastq.gz` files will be saved in the same directory as the input SRR list.
* Temporary `.sra` directories are automatically removed after conversion.
* A log file (`sra_download.log`) is generated, with detailed progress and errors.
* Failed SRRs are logged in a separate file (`sra_failed.log`), created only if there are failures.

## Notes

* Default settings use moderate CPU/memory. Customize with `--cores`, `--parallel`, and `--mem`.
* The script prints configuration at runtime.
* Must be executable:

  ```bash
  chmod +x download_sra.sh
  ```

## Troubleshooting

* Check that conda and all required tools are available in your `PATH`.
* Use `--help` to check valid usage.

## License

MIT License

## Contact

For questions, issues, or contributions, please open an issue or pull request on GitHub.
