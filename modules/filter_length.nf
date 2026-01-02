process FILTER_LENGTH {
    tag "Filtering sequences by length"
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path demux_seqs

    output:
        path 'filtered-seqs.qza'

    script:
        """
        qiime quality-filter q-score \
            --i-demux $demux_seqs \
            --p-min-length ${params.min_length} \
            --o-filtered-sequences filtered-seqs.qza \
            --o-filter-stats filter-stats.qza
        """
}
