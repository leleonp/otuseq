process MULTIQC {
    container 'public.ecr.aws/biocontainers/multiqc:1.26--pyhdfd78af_0'
    label 'process_low'

    input:
        path '*'

    output:
        path 'multiqc_report.html'

    script:
        """
        multiqc .
        """
}