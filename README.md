# TR-Errors-Pipeline
This pipeline aims to streamline the processes outline in [TR-Errors-dev](https://github.com/desilvsj/TR-Errors-dev) into a Nextflow pipeline.

## Overview
This repository contains the **Nextflow implementation** of [TR-Errors-dev](https://github.com/desilvsj/TR-Errors-dev)
It orchestrates multiple stages for analyzing **rolling-circle amplification (RCA) sequencing reads**, building consensus sequences, and refining alignments against reference transcripts.

Unlike the companion repository (`-dev`), which contains the full development history and raw Python scripts, this repo is focused on **production-ready workflow execution**. It integrates the pipeline steps into a reproducible, containerized environment suitable for HPC or cloud platforms.

Please see thed development [repo](https://github.com/desilvsj/TR-Errors-dev) for an in-depth description of the individual steps.

---

## Pipeline Structure

The pipeline currently consists of three major steps (step-3 is currently in production):

1. **Consensus Builder (Step 1)**

   * Detects repeat units within paired-end FASTQ reads.
   * Constructs a **double-consensus sequence** by phasing and integrating R1/R2.
   * Outputs: gzipped FASTQ (`output.fastq.gz`) and metadata (`metadata.txt.gz`).
   * Backed by `consensus_pipeline.py`.

2. **Quantification (Step 2)**

   * Runs [Kallisto](https://pachterlab.github.io/kallisto/) for pseudoalignment against a reference FASTA.
   * Produces BAM alignments for downstream refinement.

3. **Refiner (Step 3)**

   * Post-processes Kallisto BAMs to locate the true single consensus within the double consensus.
   * **Phase 1**: fast exact-match search near Kallisto’s index.
   * **Phase 2**: Parasail Smith–Waterman alignment (fallback, mismatch tolerant).
   * Produces a refined BAM with adjusted CIGARs and custom tags (`PH, BP, CL, MT, NM, CH, RC`).
   * Backed by `refiner.py`.

---

## Running the Pipeline

### Prerequisites

* [Nextflow](https://www.nextflow.io/) (v23+ recommended)
* Docker or Singularity (for containerized execution)
* Reference FASTA file
* Paired FASTQ reads

### Example Command

```bash
nextflow run pipeline.nf \
    --r1 inputs/example_R1.fastq.gz \
    --r2 inputs/example_R2.fastq.gz \
    --fasta inputs/reference.fa \
    --n 10000 \
    -profile docker \
    -with-docker tr-errors:latest \
    --unindexed_fasta inputs/allTranscripts.fa
```

---

## Outputs

* **Step 1**:

  * `output/Step-1/output.fastq.gz` (double consensus)
  * `output/Step-1/metadata.txt.gz`

* **Step 2**:

  * `output/Step-2/pseudoalignments.bam` (Kallisto)

* **Step 3**:

  * `output/Step-3/refined.bam` (refined BAM with consensus tags)

