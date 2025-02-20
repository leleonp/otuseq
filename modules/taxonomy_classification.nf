process TAXONOMY_CLASSIFICATION {
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'
    label 'error_retry'

    input:
    path rep_seqs
    path ref_database

    output:
    path "${rep_seqs.simpleName}_taxonomy.qza", emit: classification

    script:
    """
    qiime feature-classifier classify-sklearn \
        --i-classifier $ref_database \
        --i-reads $rep_seqs \
        --o-classification ${rep_seqs.simpleName}_taxonomy.qza \
        --p-n-jobs -2
    """
}