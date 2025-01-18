process MULTIQC {
    publishDir "${params.outdir}/multiqc", mode: 'copy'
    container 'public.ecr.aws/biocontainers/multiqc:1.26--pyhdfd78af_0'

    input:
        path '*'

    output:
        path 'multiqc_report.html'

    script:
        """
        multiqc .
        """
}