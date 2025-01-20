process TRAIN_CLASSIFIER {
    publishDir "${params.outdir}/taxonomy", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'
    label 'error_retry'

    output:
        path "classifier.qza", emit: classifier

    script:
    """
    qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads ref-sequences.qza \
    --i-reference-taxonomy ref-taxonomy.qza \
    --o-classifier classifier.qza
    --p-n-jobs -2
    """
}