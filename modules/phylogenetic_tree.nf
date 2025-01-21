process PHYLOGENETIC_TREE {
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'
    label 'error_retry'

    input:
        path rep_seqs

    output:
        path 'aligned-rep-seqs.qza'
        path 'masked-aligned-rep-seqs.qza'
        path 'unrooted-tree.qza'
        path 'rooted-tree.qza'

    script:
        """
        qiime phylogeny align-to-tree-mafft-fasttree \
            --i-sequences $rep_seqs \
            --o-alignment aligned-rep-seqs.qza \
            --o-masked-alignment masked-aligned-rep-seqs.qza \
            --o-tree unrooted-tree.qza \
            --o-rooted-tree rooted-tree.qza \
            --p-n-threads auto
        """
}