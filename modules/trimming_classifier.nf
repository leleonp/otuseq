process TRIMMING_CLASSIFIER {
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'
    label 'error_retry'

    input:
        path classifier

    output:
        path "trimmed_classifier.qza", emit: trimmed_classifier

    script:
    """
    qiime feature-classifier extract-reads \
    --i-sequences ref-sequences.qza \
    --p-f-primer ${params.forward_primer} \
    --p-r-primer ${params.reverse_primer} \
    --o-reads trimmed_classifier.qza \
    --p-n-jobs $task.cpus
    """
}