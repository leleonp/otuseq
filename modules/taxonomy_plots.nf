process TAXONOMY_PLOTS {
    tag "Generating taxonomy plots for level ${level}"
    container "quay.io/biocontainers/mulled-v2-5d3f49b113a76edda01cd831e89a1c87d7d350da:3ad8ce28b8e5f8bb86e4ce2eaf3897f80bd4a5ef-0"
    label 'process_low'
    publishDir "${params.outdir}/taxonomy_plots", mode: 'copy'

    input:
        tuple val(level), path(table_qza), path(taxonomy)

    output:
        path "taxonomy_level${level}_histogram.pdf"
        path "taxonomy_level${level}_histogram.png"

    script:
        """
        plot_taxonomy.py $table_qza $taxonomy $level taxonomy
        """
}
