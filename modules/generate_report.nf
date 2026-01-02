process GENERATE_REPORT {
    tag "Generating comprehensive analysis report"
    container 'rocker/verse:latest'
    label 'process_low'
    publishDir "${params.outdir}/report", mode: 'copy'

    input:
        path "inputs/*"
        path template

    output:
        path "OTUseq_Report.html"
        path "OTUseq_Report_files/*", optional: true

    script:
        """
        #!/usr/bin/env Rscript

        # Install required packages if not present
        required_packages <- c(
            "knitr", "rmarkdown", "dplyr", "ggplot2", "tidyr",
            "kableExtra", "plotly", "DT", "scales", "readr",
            "jsonlite", "readxl"
        )

        for (pkg in required_packages) {
            if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
                install.packages(pkg, repos = "https://cloud.r-project.org/", quiet = TRUE)
            }
        }

        # Organize input files
        system("mkdir -p multiqc alpha_diversity beta_diversity rarefaction taxonomy_plots abundance_tables")

        # Copy files to appropriate directories
        system("find inputs -name 'multiqc*' -exec cp -r {} ./multiqc/ \\\\; || true")
        system("find inputs -name '*alpha*' -exec cp -r {} ./alpha_diversity/ \\\\; || true")
        system("find inputs -name '*beta*' -exec cp -r {} ./beta_diversity/ \\\\; || true")
        system("find inputs -name '*rarefaction*' -exec cp -r {} ./rarefaction/ \\\\; || true")
        system("find inputs -name '*histogram*' -exec cp {} ./taxonomy_plots/ \\\\; || true")
        system("find inputs -name '*.xlsx' -exec cp {} ./abundance_tables/ \\\\; || true")

        # Set parameters
        params <- list(
            project_name = "Análisis Microbioma OTUseq",
            outdir = "."
        )

        # Render the report
        rmarkdown::render(
            input = "${template}",
            output_file = "OTUseq_Report.html",
            params = params,
            envir = new.env()
        )

        cat("Reporte generado exitosamente: OTUseq_Report.html\\n")
        """
}
