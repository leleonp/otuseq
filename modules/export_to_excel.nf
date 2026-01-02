process EXPORT_TO_EXCEL {
    tag "Converting BIOM tables to Excel format"
    conda "bioconda::biom-format conda-forge::pandas conda-forge::openpyxl"
    label 'process_low'

    input:
        tuple val(level), path(table_qza), path(taxonomy)

    output:
        path "level-${level}-abundance.xlsx"

    script:
        """
        #!/usr/bin/env python3
        import pandas as pd
        import biom
        import os
        import tempfile
        import zipfile
        import json

        # Extract the BIOM file from the QZA archive
        with zipfile.ZipFile('${table_qza}', 'r') as zip_ref:
            # Find the data directory
            data_files = [f for f in zip_ref.namelist() if f.endswith('.biom')]
            if data_files:
                biom_file = data_files[0]
                zip_ref.extract(biom_file, '.')

                # Load BIOM table
                table = biom.load_table(biom_file)

                # Convert to DataFrame
                df = table.to_dataframe()

                # Transpose to have samples as rows and taxa as columns
                df = df.T

                # Calculate total counts and relative abundance
                total_counts = df.sum(axis=1)
                rel_abundance = df.div(df.sum(axis=1), axis=0) * 100

                # Create Excel writer
                with pd.ExcelWriter('level-${level}-abundance.xlsx', engine='openpyxl') as writer:
                    # Write absolute counts
                    df.to_excel(writer, sheet_name='Absolute_Counts')

                    # Write relative abundance
                    rel_abundance.to_excel(writer, sheet_name='Relative_Abundance')

                    # Write summary statistics
                    summary = pd.DataFrame({
                        'Total_Reads': total_counts,
                        'Observed_Taxa': (df > 0).sum(axis=1)
                    })
                    summary.to_excel(writer, sheet_name='Summary')
        """
}
