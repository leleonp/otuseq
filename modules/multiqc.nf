process MULTIQC {
    container 'community.wave.seqera.io/library/multiqc:1.26--8a1b8d5784388670'
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
