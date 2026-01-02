process TAXONOMY_PLOTS {
    tag "Generating taxonomy plots for level ${level}"
    container "community.wave.seqera.io/library/biom-format_matplotlib_pandas_seaborn:latest"
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
