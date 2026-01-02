process TAXONOMY_PLOTS {
    tag "Generating taxonomy plots for level ${level}"
    conda "bioconda::biom-format conda-forge::pandas conda-forge::matplotlib conda-forge::seaborn"
    container "quay.io/biocontainers/mulled-v2-e8ad96e77e18a48385c7e792f54fde77166eca77:b1eca6af4cbe6c9e0f3b6f1f0e1e8e5f5e5c8b0a-0"
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
