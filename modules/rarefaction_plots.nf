process RAREFACTION_PLOTS {
    tag "Generating rarefaction plots and Excel files"
    container "community.wave.seqera.io/library/pandas_matplotlib_seaborn_openpyxl:latest"
    label 'process_low'
    publishDir "${params.outdir}/rarefaction", mode: 'copy'

    input:
        path rarefaction_qzv

    output:
        path "rarefaction_curves.pdf"
        path "rarefaction_curves.png"

    script:
        """
        rarefaction_to_excel.py $rarefaction_qzv rarefaction
        """
}
