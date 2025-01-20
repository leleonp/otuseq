process QIIME2_IMPORT {
    publishDir "${params.outdir}/qiime2", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        tuple val(sample_id), path(forward_fastq), path(reverse_fastq)

    output:
        path "demux.qza", emit: demux

    script:
        """
        # Create a directory for the input files
        mkdir -p reads/

        # Symlink the input files to the expected location
        mv ${forward_fastq} reads/${forward_fastq}
        mv ${reverse_fastq} reads/${reverse_fastq}

        qiime tools import \
            --type 'SampleData[PairedEndSequencesWithQuality]' \
            --input-path reads \
            --input-format CasavaOneEightSingleLanePerSampleDirFmt \
            --output-path demux.qza
        """
}