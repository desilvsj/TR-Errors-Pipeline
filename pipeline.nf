#!/home/desil/.local/bin/nextflow

//rm -rf .nextflow* work/ results/
//nextflow run pipeline.nf -profile docker --r1 inputs/example_trimmed_R1.fastq --r2 inputs/example_trimmed_R2.fastq --n  10000 -with-docker tr-errors:latest --unindexed_fasta inputs/allTranscripts.fa

/*
 * Running our consensus
 */

process consensusBuilder {
  publishDir 'output/Step-1', mode: 'copy', overwrite: true
  container 'tr-errors:latest'

  input:
    path r1_input
    path r2_input
    val  max_reads
    path consensus_py

  output:
    path 'output.fastq.gz'
    path 'metadata.txt.gz'

  script:
  """
  python3 $consensus_py $r1_input $r2_input --max-reads $max_reads --fastq-out output.fastq.gz --meta-out metadata.txt.gz
  """
}

process kallistoIndex{
  publishDir 'output/Step-2.1', mode: 'copy'
  container 'tr-errors:latest'

  input:
    path unindexed_fasta

  output:
    path 'allTranscripts.idx'

  script:
  """
  kallisto index -i allTranscripts.idx $unindexed_fasta
  """

}

process kallistoRun {
  publishDir 'output/Step-2.2', mode: 'copy'
  container 'tr-errors:latest'

  input:
    path indexed_fasta
    path dcs_fastq

  output:
    path 'kallisto'

  script:
  """
  kallisto quant -i $indexed_fasta -o kallisto --pseudobam --single -l 60 -s 20 $dcs_fastq
  """
}

//python3 src/refiner_v4.py kallisto/pseudoalignments.bam kallisto/allTranscripts.fa -o refined/test -n 10000

// process refiner {
//   publishDir 'output/Step3', mode: 'copy'
//   container 'tr-errors:latest'

//   input:
//     path refiner_py
//     path pseudoalignments_bam
//     path allTrasncripts_fa
//     path max_reads
    

//   output:
//     path 'refined.bam'

//   script:
//   """
//   python3 $refiner_py $pseudoalignments_bam $allTrasncripts_fa -o refined.bam -n $max_reads
//   """
// }

/*
 * Pipeline parameters
 */
params.r1 = null
params.r2 = null
params.unindexed_fasta = null
params.n  = 10000

workflow {
  if( !params.r1 || !params.r2 || !params.unindexed_fasta ){
    log.error 'Provide --r1, --r2, and --unindexed_fasta'; System.exit(1)
  }

  // One channel; one item per sample
  r1_ch = Channel.fromPath(params.r1)
  r2_ch = Channel.fromPath(params.r2)
  fasta_ch = Channel.fromPath(params.unindexed_fasta)
  n_max_ch = Channel.of(params.n)
  consensus_py_ch = Channel.fromPath('src/consensus_builder.py')
  refiner_py_ch = Channel.fromPath('src/refiner.py')

  // Step 1
  step1_outputs = consensusBuilder(r1_ch, r2_ch, n_max_ch, consensus_py_ch)
  dcs_fastq_ch = step1_outputs[0]

  // Step 2: run kallisto
  //Step 2.1 Indexing
  step2_1_outputs = kallistoIndex(fasta_ch)
  index_ch = step2_1_outputs[0]
  
  //Step 2.2 Pseudoalignment
  step2_2_outputs = kallistoRun(index_ch, dcs_fastq_ch)
  pseudoalignments_ch = step2_2_outputs[0]

  // //Step 3
  // refiner(refiner_py_ch, pseudoalignments_ch, fasta_ch, n_max_ch)



}
