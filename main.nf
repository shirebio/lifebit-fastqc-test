nextflow.enable.dsl=2

  params.input = ''  // Specify the input TSV file via --input parameter

  /*
  * FastQC_Pipeline 
  */ 

process run_fastqc_on_R1_and_R2 {
    input:
    val sample_name
    path R1
    path R2

    output:
    path '${sample_name}_R1_fastqc.html', emit: R1_fastqc_report
    path '${sample_name}_R2_fastqc.html', emit: R2_fastqc_report

    container 'public.ecr.aws/a0h7i1n6/shire-studio:fastqc-5'
    memory '8 GB'
    cpus 1

    script:
    """
    mv ${R2} ${sample_name}_R2.fastq.gz && mv ${R1} ${sample_name}_R1.fastq.gz && mkdir -p Fastqc_R1 Fastqc_R2 && fastqc --nogroup --outdir Fastqc_R1 ${sample_name}_R1.fastq.gz && mv Fastqc_R1/*fastqc.html ${sample_name}_R1_fastqc.html && fastqc --nogroup --outdir Fastqc_R2 ${sample_name}_R2.fastq.gz && mv Fastqc_R2/*fastqc.html ${sample_name}_R2_fastqc.html
    """
  }

workflow {
    // Read the TSV file and split into separate channels
    Channel
        .fromPath(params.input)
        .splitCsv(header: true, sep: '	')
        .map { row ->
            def sample_name = row.sample_name
            def R1 = file(row.R1)
            def R2 = row.containsKey('R2') ? file(row.R2) : null
            [ sample_name, R1, R2 ]
        }
        .transpose()
        .set { sample_name, R1, R2 }

    run_fastqc_on_R1_and_R2(sample_name, R1, R2)
}
