/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { REMOVE_HOMOPOLYMERS } from '../modules/remove_homopolymers'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow OTUSEQ {

    samples = Channel
        .fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map { row -> tuple(row.sample_id, file(row.forward), file(row.reverse)) }

    take:
        samples // channel: samplesheet read in from --input

    main:
        REMOVE_HOMOPOLYMERS(samples)
        forw_reads = REMOVE_HOMOPOLYMERS.out.forw_read.map { file ->
            def nameParts = file.name.tokenize('_')
            def baseName = nameParts[0..-3].join('_')
            [baseName, file]
        }

        rev_reads = REMOVE_HOMOPOLYMERS.out.rev_read.map { file ->
            def nameParts = file.name.tokenize('_')
            def baseName = nameParts[0..-3].join('_')
            [baseName, file]
        }
        filt_reads = forw_reads.combine(rev_reads, by: 0)
        filt_reads.view()

//    emit:

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
