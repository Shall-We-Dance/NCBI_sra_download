# NCBI SRA Download Script

A Bash script for downloading sequencing data from the NCBI SRA database, converting `.sra` files to `.fastq`, compressing the output, and cleaning up intermediate files. This version adds parallel processing, progress bars, improved error handling, and enhanced logging.

## Features

* Batch download of SRA data from NCBI using a list of SRR accession numbers.
* FASTQ conversion via `fasterq-dump` with progress monitoring.
* Parallel compression of FASTQ files with `pigz`.
* Automatic cleanup of intermediate SRA folders.
* Fail-safe mechanism that logs failed SRR downloads or conversions.
* Color-coded log output to indicate download, warning, and error statuses.
* Automatically activates a conda environment with the required tools.

## Usage

```bash
./download_sra.sh <srr_list.txt>
```

### Example

```bash
./download_sra.sh ./SRR_Acc_list.txt
```

The script expects:

* A plain text file (`srr_list.txt`) with one SRR accession per line. This list can be generated from the NCBI SRA website.
* A conda environment with required tools installed.

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

* Uses `1/4` of available CPU threads for downloading and conversion.
* Uses 16 threads for compression via `pigz`.
* `pv` is used for progress bars during download and conversion (if installed).
* The script must be executable:

  ```bash
  chmod +x download_sra.sh
  ```

## Troubleshooting

* Ensure all required tools are installed and accessible in the `ncbi_sra_download` conda environment.
* If conda is not found, make sure it's in your `PATH` or adjust the script accordingly.
* If no progress is shown during download or conversion, ensure that `pv` is installed and available in your system path.

## License

MIT License

## Contact

For questions, issues, or contributions, please open an issue or pull request on GitHub.
