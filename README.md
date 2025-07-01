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
./download_sra.sh <srr_list.txt> [--cores N] [--parallel N] [--mem XMB]
```

### Options

* `--cores N`   Number of CPU threads per SRR conversion (default: 1/4 of total CPU cores).
* `--parallel N`  Number of parallel SRR processes (default: 4).
* `--mem XMB`   Memory allocated per conversion in MB (default: 4096MB).
* `-h`, `--help`  Show usage and exit.

### Example

```bash
./download_sra.sh SRR_Acc_list.txt --cores 8 --parallel 2 --mem 8192MB
```

## Requirements

### Software

* [conda](https://docs.conda.io/en/latest/)
* [sra-tools](https://github.com/ncbi/sra-tools) (must include `fasterq-dump`, `sra-info`, `prefetch`)
* [pigz](https://zlib.net/pigz/)
* [pv](https://github.com/atheme/pv) (for progress bar)

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
