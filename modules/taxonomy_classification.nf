process TAXONOMY_CLASSIFICATION {
    publishDir "${params.outdir}/taxonomy", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2' 

    input:
        path rep_seqs
        path ref_database

    output:
        path 'taxonomy.qza'

    script:
        """
        qiime feature-classifier classify-sklearn \
            --i-classifier $ref_database \
            --i-reads $rep_seqs \
            --o-classification taxonomy.qza
        """
}