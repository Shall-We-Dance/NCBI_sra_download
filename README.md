# NCBI SRA Download Script

A Bash script for downloading sequencing data from the NCBI SRA database, converting `.sra` files to `.fastq`, compressing the output, and cleaning up intermediate files.

## Features

* Batch download of SRA data from NCBI using a list of SRR accession numbers
* FASTQ conversion via `fasterq-dump`
* Parallel compression of FASTQ files with `pigz`
* Automatic cleanup of intermediate SRA folders
* Automatic conda environment activation

## Usage

```bash
./download_sra.sh <srr_list.txt>
```

### Example

```bash
./download_sra.sh ./SRR_Acc_list.txt
```

The script expects:

* A plain text file (`srr_list.txt`) with one SRR accession per line, which can be generated from the SRA website.
* An conda environment with required tools installed


## Requirements

### Software

* [conda](https://docs.conda.io/en/latest/)
* [sra-tools](https://github.com/ncbi/sra-tools) (must include `fasterq-dump`, `sra-info`, `prefetch`)
* [pigz](https://zlib.net/pigz/)

### Conda Environment

Example conda environment (`ncbi_sra_download`) configuration:

```bash
conda create -n ncbi_sra_download sra-tools pigz -c bioconda
```

## Output

* `.fastq.gz` files will be saved in the same directory as the input SRR list
* Temporary `.sra` directories are automatically removed after conversion

## Notes

* Uses `1/4` of available CPU threads for downloading/conversion
* Uses 16 threads for compression via `pigz`
* Script must be executable:

  ```bash
  chmod +x download_sra.sh
  ```

## Troubleshooting

* Ensure all required tools are installed and accessible in the `ncbi_sra_download` conda environment
* If conda is not found, make sure it's in your `PATH` or adjust the script accordingly

## License

MIT License

## Contact

For questions, issues, or contributions, please open an issue or pull request on GitHub.
