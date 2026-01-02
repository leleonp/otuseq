/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { REMOVE_HOMOPOLYMERS       } from '../modules/remove_homopolymers'
include { FASTQC                    } from '../modules/fastqc'
include { CUTADAPT                  } from '../modules/cutadapt'
include { MULTIQC                   } from '../modules/multiqc'
include { QIIME2_IMPORT             } from '../modules/qiime2_import'
include { VSEARCH_DEREPLICATE       } from '../modules/vsearch_dereplicate'
include { VSEARCH_CLUSTER           } from '../modules/vsearch_cluster'
include { VSEARCH_MERGE             } from '../modules/vsearch_merge'
include { CHIMERA_FILTERING         } from '../modules/chimera_filtering'
include { TAXONOMY_CLASSIFICATION   } from '../modules/taxonomy_classification'
include { FILTER_TAXA               } from '../modules/filter_taxa'
include { ABUNDANCE_TABLES          } from '../modules/abundance_tables'
include { EXPORT_TO_EXCEL           } from '../modules/export_to_excel'
include { TAXONOMY_BARPLOTS         } from '../modules/taxonomy_barplots'
include { TAXONOMY_PLOTS            } from '../modules/taxonomy_plots'
include { ALPHA_DIVERSITY           } from '../modules/alpha_diversity'
include { BETA_DIVERSITY            } from '../modules/beta_diversity'
include { RAREFACTION               } from '../modules/rarefaction'
include { RAREFACTION_PLOTS         } from '../modules/rarefaction_plots'
include { GENERATE_REPORT           } from '../modules/generate_report'
// include { TRAIN_CLASSIFIER          } from '../modules/train_classifier'
// include { TRIMMING_CLASSIFIER       } from '../modules/trimming_classifier'
include { MERGE_TAXONOMY            } from '../modules/merge_taxonomy'

include { PHYLOGENETIC_TREE         } from '../modules/phylogenetic_tree'
//include { CONVERT_TO_PHYLOSEQ       } from '../modules/convert_to_phyloseq'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow OTUSEQ {
    take:
        samples
        database
        excluded_taxa
        forward_primer
        reverse_primer

    main:
        // TRAIN_CLASSIFIER()
        // TRIMMING_CLASSIFIER(TRAIN_CLASSIFIER.out.classifier)
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

        // Quality Control
        FASTQC(samples)

        // Primer Trimming
        CUTADAPT(filt_reads,
                forward_primer,
                reverse_primer)    

        // MultiQC Report
        multiqc_ch = FASTQC.out.mix(CUTADAPT.out.logs)
        MULTIQC(multiqc_ch.collect())


        trimmed_reads = CUTADAPT.out.trimmed_reads.map { file ->
            def nameParts = file[0].name.tokenize('_')
            def baseName = nameParts[0..-5].join('_')
            [baseName, file[0], file[1]]
        }

        // QIIME2 Import
        QIIME2_IMPORT(trimmed_reads.collect())

        // VSEARCH steps
        VSEARCH_DEREPLICATE(QIIME2_IMPORT.out)

        VSEARCH_CLUSTER(VSEARCH_DEREPLICATE.out.derep_table, VSEARCH_DEREPLICATE.out.derep_rep_seqs)

        // Remove chimeric sequences
        CHIMERA_FILTERING(VSEARCH_CLUSTER.out.clustered_table, VSEARCH_CLUSTER.out.clustered_rep_seqs)

        // Perform taxonomic classification on individual sequences
        TAXONOMY_CLASSIFICATION(CHIMERA_FILTERING.out.rep_seqs, database)

        //Merge taxonomy
        // MERGE_TAXONOMY(TAXONOMY_CLASSIFICATION.out.coll)

        // Filter Unwanted Taxa (chloroplasts and mitochondria)
        FILTER_TAXA(CHIMERA_FILTERING.out.table,
                    TAXONOMY_CLASSIFICATION.out.classification,
                    excluded_taxa)

        Channel
            .of(2, 3, 4, 5, 6, 7)
            .combine(FILTER_TAXA.out)
            .combine(TAXONOMY_CLASSIFICATION.out.classification)
            .set { abundance_table_input }

        // Generate Abundance Tables (BIOM format)
        ABUNDANCE_TABLES(abundance_table_input)

        // Export to Excel
        EXPORT_TO_EXCEL(abundance_table_input)

        // Generate taxonomy barplots
        TAXONOMY_BARPLOTS(FILTER_TAXA.out, TAXONOMY_CLASSIFICATION.out.classification)

        // Generate custom taxonomy histograms
        TAXONOMY_PLOTS(abundance_table_input)

        // Phylogenetic Tree
        PHYLOGENETIC_TREE(CHIMERA_FILTERING.out.rep_seqs)

        // Calculate Alpha Diversity Indices
        ALPHA_DIVERSITY(FILTER_TAXA.out)

        // Calculate Beta Diversity
        BETA_DIVERSITY(FILTER_TAXA.out, PHYLOGENETIC_TREE.out[3])

        // Generate Rarefaction Curves
        RAREFACTION(FILTER_TAXA.out, PHYLOGENETIC_TREE.out[3])

        // Export rarefaction plots
        RAREFACTION_PLOTS(RAREFACTION.out[0])

        // Generate comprehensive report if requested
        if (params.report) {
            // Collect all outputs for report
            report_inputs = Channel.empty()
                .mix(MULTIQC.out)
                .mix(ALPHA_DIVERSITY.out[5])
                .mix(BETA_DIVERSITY.out[8])
                .mix(RAREFACTION.out[1])
                .mix(TAXONOMY_PLOTS.out[0])
                .mix(TAXONOMY_PLOTS.out[1])
                .mix(EXPORT_TO_EXCEL.out)
                .collect()

            // Get report template
            report_template = Channel.fromPath("${projectDir}/assets/templates/report_template.qmd")

            GENERATE_REPORT(
                report_inputs,
                report_template
            )
        }

    // CONVERT_TO_PHYLOSEQ(
    //     FILTER_TAXA.out,
    //     TAXONOMY_CLASSIFICATION.out,
    //     PHYLOGENETIC_TREE.out.rooted_tree,
    //     params.metadata
    // )


//    emit:

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
