# Changelog - OTUseq Pipeline

## Última Actualización: Sistema de Reportes Automáticos

### ✨ Nueva Funcionalidad: Generación Automática de Reportes (--report)

Se ha implementado un sistema completo de generación de reportes automáticos en español usando Quarto (.qmd).

#### Características:
- **Parámetro:** `--report` (boolean, default: false)
- **Formato:** HTML auto-contenido
- **Idioma:** Español
- **Contenido:** Todas las métricas y gráficos del análisis

#### Archivos creados:
1. `assets/templates/report_template.qmd` - Template Quarto en español
2. `modules/generate_report.nf` - Módulo de generación de reporte
3. `bin/collect_read_stats.py` - Script para recopilar estadísticas
4. `docs/REPORT_FEATURE.md` - Documentación completa de la funcionalidad

#### Secciones del reporte:
- ✅ Control de Calidad (FastQC/MultiQC)
- ✅ Seguimiento de lecturas (Read Tracking)
- ✅ Curvas de Rarefacción
- ✅ Diversidad Alfa (Shannon, Chao1, ACE, Simpson)
- ✅ Diversidad Beta (Bray-Curtis, Jaccard, UniFrac)
- ✅ Composición Taxonómica (Phylum → Género)
- ✅ Tablas de Abundancia interactivas
- ✅ Parámetros del Pipeline
- ✅ Conclusiones y Recomendaciones

#### Uso:
```bash
nextflow run main.nf --input samples.csv --outdir results --report -profile docker
```

---

## Nuevas Funcionalidades Implementadas

### 2.1 Trimming y Control de Calidad

#### ✅ Implementado previamente:
- Eliminación de secuencias ambiguas (N)
- Eliminación de Homopolímeros >8pb
- Eliminación de Primers y adaptadores (5' y 3')

#### ✅ Nuevas implementaciones:
- **Filtro de longitud mínima**: `modules/filter_length.nf`
  - Elimina secuencias <200pb
  - Configurable vía `params.min_length` (default: 200)

- **Detección de quimeras**: `modules/chimera_filtering.nf`
  - Algoritmo VSEARCH UCHIME de-novo
  - Remueve secuencias quiméricas
  - Genera estadísticas de quimeras detectadas

### 2.2 Asignación Taxonómica

#### ✅ Implementado previamente:
- Clasificación con base de datos SILVA 138
- Eliminación de Cloroplastos y Mitocondrias
- Clustering de OTUs al 97% de identidad

#### ✅ Nuevas implementaciones:
- **Índices de Diversidad Alfa**: `modules/alpha_diversity.nf`
  - Shannon diversity index
  - Chao1 richness estimator
  - ACE richness estimator
  - Simpson diversity index
  - Observed features (riqueza de OTUs)
  - Exporta resultados en formato TSV

- **Diversidad Beta**: `modules/beta_diversity.nf`
  - Bray-Curtis dissimilarity
  - Jaccard distance
  - Weighted UniFrac (filogenético)
  - Unweighted UniFrac (filogenético)
  - Análisis de PCoA para cada métrica
  - Exporta matrices de distancia y coordenadas PCoA

### 3. Material de Entrega

#### ✅ Nuevas implementaciones:

- **Exportación a Excel**: `modules/export_to_excel.nf`
  - Convierte tablas BIOM a formato Excel (.xlsx)
  - Genera 3 hojas por nivel taxonómico:
    - Absolute_Counts: Conteos absolutos
    - Relative_Abundance: Abundancia relativa (%)
    - Summary: Estadísticas por muestra

- **Gráficos de Asignación Taxonómica**:
  - `modules/taxonomy_barplots.nf`: Barplots interactivos (QIIME2 visualization)
  - `modules/taxonomy_plots.nf`: Histogramas personalizados
  - `bin/plot_taxonomy.py`: Script Python para gráficos
  - Genera histogramas de:
    - Top 20 taxa por nivel taxonómico
    - Abundancia absoluta
    - Abundancia relativa (%)
  - Formatos: PDF y PNG de alta resolución (300 DPI)

- **Curvas de Rarefacción**:
  - `modules/rarefaction.nf`: Genera curvas de rarefacción
  - `modules/rarefaction_plots.nf`: Exporta gráficos
  - `bin/rarefaction_to_excel.py`: Conversión a Excel y PDF
  - Métricas incluidas:
    - Shannon diversity
    - Chao1
    - Observed features
    - ACE
  - 20 puntos de muestreo hasta la profundidad mediana
  - Visualizaciones interactivas (QZV) y archivos exportados

## Estructura de Salida del Pipeline

```
results/
├── taxonomy_plots/
│   ├── taxa-bar-plots.qzv                 # Visualización interactiva
│   ├── taxonomy_level2_histogram.pdf      # Phylum
│   ├── taxonomy_level3_histogram.pdf      # Class
│   ├── taxonomy_level4_histogram.pdf      # Order
│   ├── taxonomy_level5_histogram.pdf      # Family
│   ├── taxonomy_level6_histogram.pdf      # Genus
│   └── taxonomy_level7_histogram.pdf      # Species
│
├── diversity/
│   ├── alpha_diversity/
│   │   ├── shannon/alpha-diversity.tsv
│   │   ├── chao1/alpha-diversity.tsv
│   │   ├── ace/alpha-diversity.tsv
│   │   ├── simpson/alpha-diversity.tsv
│   │   └── observed_features/alpha-diversity.tsv
│   │
│   └── beta_diversity/
│       ├── bray_curtis/distance-matrix.tsv
│       ├── jaccard/distance-matrix.tsv
│       ├── weighted_unifrac/distance-matrix.tsv
│       └── unweighted_unifrac/distance-matrix.tsv
│
├── rarefaction/
│   ├── alpha-rarefaction.qzv
│   ├── rarefaction_curves.pdf
│   └── rarefaction_curves.png
│
├── abundance_tables/
│   ├── level-2-abundance.xlsx             # Phylum
│   ├── level-3-abundance.xlsx             # Class
│   ├── level-4-abundance.xlsx             # Order
│   ├── level-5-abundance.xlsx             # Family
│   ├── level-6-abundance.xlsx             # Genus
│   └── level-7-abundance.xlsx             # Species
│
└── phylogenetic_tree/
    ├── aligned-rep-seqs.qza
    ├── masked-aligned-rep-seqs.qza
    ├── unrooted-tree.qza
    └── rooted-tree.qza
```

## Nuevos Parámetros de Configuración

```groovy
params {
    min_length = 200                       // Longitud mínima de secuencias (pb)
    perc_identity = 0.97                   // Identidad para clustering de OTUs
    excluded_taxa = 'mitochondria,chloroplast'  // Taxa a excluir
}
```

## Flujo de Trabajo Actualizado

```
Input FASTQ
    ↓
Remove Homopolymers (>8bp) & Ambiguous bases (N)
    ↓
Quality Control (FastQC)
    ↓
Primer Trimming (Cutadapt)
    ↓
Filter by Length (≥200bp)                  [NUEVO]
    ↓
Import to QIIME2
    ↓
Merge Paired-End Reads
    ↓
Dereplicate Sequences
    ↓
Cluster OTUs (97% identity)
    ↓
Remove Chimeras (VSEARCH UCHIME)           [NUEVO]
    ↓
Taxonomic Classification (SILVA 138)
    ↓
Filter Taxa (remove mitochondria/chloroplast)
    ↓
├─→ Abundance Tables (Excel)               [NUEVO]
├─→ Taxonomy Plots (PDF/PNG)               [NUEVO]
├─→ Alpha Diversity Indices                [NUEVO]
├─→ Beta Diversity Matrices                [NUEVO]
├─→ Rarefaction Curves (PDF/Excel)         [NUEVO]
└─→ Phylogenetic Tree
```

## Módulos Creados

1. `modules/filter_length.nf` - Filtrado por longitud
2. `modules/chimera_filtering.nf` - Detección de quimeras
3. `modules/alpha_diversity.nf` - Índices de diversidad alfa
4. `modules/beta_diversity.nf` - Diversidad beta y PCoA
5. `modules/export_to_excel.nf` - Conversión BIOM a Excel
6. `modules/taxonomy_barplots.nf` - Barplots taxonómicos
7. `modules/taxonomy_plots.nf` - Histogramas personalizados
8. `modules/rarefaction.nf` - Curvas de rarefacción
9. `modules/rarefaction_plots.nf` - Exportación de curvas

## Scripts Auxiliares

1. `bin/plot_taxonomy.py` - Generación de histogramas taxonómicos
2. `bin/rarefaction_to_excel.py` - Exportación de curvas de rarefacción

## Requisitos del Pipeline

### Herramientas:
- QIIME2 2023.2
- VSEARCH
- Cutadapt 4.9
- FastQC/MultiQC
- Python 3 con: pandas, matplotlib, seaborn, biom-format, openpyxl

### Contenedores:
- `public.ecr.aws/b1n7j4p9/qiime2:2023.2`
- `public.ecr.aws/biocontainers/cutadapt:4.9--py310h1fe012e_3`
- `community.wave.seqera.io/library/pandas_matplotlib_seaborn_biom-format:latest`
- `community.wave.seqera.io/library/pandas_openpyxl_biom-format:latest`

## Notas de Uso

Para ejecutar el pipeline con las nuevas funcionalidades:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --min_length 200 \
    -profile docker
```

## Cumplimiento de Requisitos

### ✅ Análisis de Datos - Trimming
- [x] Eliminación de secuencias ambiguas (N)
- [x] Eliminación de Homopolímeros >8pb
- [x] Eliminación de Primers y adaptadores (5' y 3')
- [x] Eliminar secuencias <200pb
- [x] Eliminar quimeras (VSEARCH UCHIME)

### ✅ Asignación Taxonómica
- [x] Clasificar con base de datos SILVA (última versión: 138)
- [x] Eliminar Cloroplastos y Mitocondrias
- [x] Asignar y clasificar OTUs
- [x] Calcular diversidad alfa (Shannon, Chao1, ACE, Simpson)
- [x] Calcular diversidad beta (Bray-Curtis, Jaccard, UniFrac)

### ✅ Documentación y Material de Entrega
- [x] Tablas de abundancia en Excel (PHYLA, CLASE, ORDEN, FAMILIA, GÉNERO)
- [x] Conteos absolutos y abundancia relativa (%)
- [x] Gráficos histograma de asignación taxonómica (todos los niveles)
- [x] Índices de diversidad en formato exportable
- [x] Curvas de rarefacción en PDF y formatos exportables

---

**Fecha de actualización**: 2025-12-30
**Versión**: 2.12.0
