process TAXONOMY_PLOTS {
    tag "Generating taxonomy plots for level ${level}"
    container "895739677619.dkr.ecr.us-east-1.amazonaws.com/otuseq-taxonomy-plots:1.0.0"
    conda "bioconda::biom-format conda-forge::pandas conda-forge::matplotlib conda-forge::seaborn"
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
