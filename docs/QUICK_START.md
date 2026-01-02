# Guía de Inicio Rápido - OTUseq Pipeline

## 🚀 Inicio Rápido en 3 Pasos

### 1️⃣ Instalar Prerequisitos

```bash
# Instalar Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Verificar instalación
nextflow -version
```

### 2️⃣ Preparar Samplesheet

Crear archivo `samples.csv`:

```csv
sample_id,forward,reverse
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
sample3,/path/to/sample3_R1.fastq.gz,/path/to/sample3_R2.fastq.gz
```

### 3️⃣ Ejecutar el Pipeline

#### Opción A: Con Docker (Recomendado)

```bash
# Usando script helper
./bin/run_docker.sh --input samples.csv --report

# O directamente
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    --report \
    -profile docker
```

#### Opción B: En AWS Batch

```bash
# Usando script helper
./bin/run_aws.sh \
    --project MI_PROYECTO \
    --input s3://mi-bucket/samples.csv \
    --report

# O directamente
nextflow run main.nf \
    --input s3://mi-bucket/samples.csv \
    --outdir s3://mi-bucket/results \
    --report \
    -profile aws_batch
```

---

## 📋 Perfiles Disponibles

| Perfil | Uso | Comando |
|--------|-----|---------|
| `docker` | Docker local | `-profile docker` |
| `docker,arm` | Mac M1/M2/M3 | `-profile docker,arm` |
| `aws_batch` | AWS Batch | `-profile aws_batch` |
| `conda` | Conda/Mamba | `-profile conda` |

---

## 🎯 Ejemplos Comunes

### Análisis Básico

```bash
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    -profile docker
```

### Con Reporte Completo

```bash
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    --report \
    -profile docker
```

### Personalizar Parámetros

```bash
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    --min_length 250 \
    --perc_identity 0.99 \
    --forward_primer 'CUSTOMPRIMER' \
    --report \
    -profile docker
```

### Reanudar Ejecución

```bash
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    -profile docker \
    -resume
```

---

## 📊 Resultados

Estructura de salida:

```
results/
├── report/
│   └── OTUseq_Report.html          ← REPORTE PRINCIPAL
├── abundance_tables/
│   ├── level-2-abundance.xlsx      ← Phylum
│   ├── level-3-abundance.xlsx      ← Clase
│   ├── level-4-abundance.xlsx      ← Orden
│   ├── level-5-abundance.xlsx      ← Familia
│   └── level-6-abundance.xlsx      ← Género
├── taxonomy_plots/
│   ├── taxonomy_level2_histogram.pdf
│   ├── taxonomy_level3_histogram.pdf
│   └── ...
├── alpha_diversity/
│   ├── shannon/
│   ├── chao1/
│   └── ...
├── beta_diversity/
│   ├── bray_curtis/
│   └── ...
└── rarefaction/
    ├── rarefaction_curves.pdf
    └── alpha-rarefaction.qzv
```

---

## 🔧 Parámetros Principales

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `--input` | - | **REQUERIDO** Samplesheet CSV |
| `--outdir` | - | **REQUERIDO** Directorio de salida |
| `--forward_primer` | CCTAYGGGRBGCASCAG | Primer forward |
| `--reverse_primer` | GGACTACNNGGGTATCTAAT | Primer reverse |
| `--min_length` | 200 | Longitud mínima (pb) |
| `--perc_identity` | 0.97 | Identidad clustering (0-1) |
| `--report` | false | Generar reporte HTML |
| `--ref_database` | SILVA 138 | Base de datos taxonómica |

---

## 🐛 Solución de Problemas

### Error: Docker no está corriendo

```bash
# Iniciar Docker Desktop o el daemon
# En Mac: Abrir Docker Desktop
# En Linux:
sudo systemctl start docker
```

### Error: Permisos denegados

```bash
# Dar permisos al directorio de salida
chmod -R 755 results/
```

### Pipeline se detiene

```bash
# Reanudar con -resume
nextflow run main.nf ... -resume
```

### Ver logs detallados

```bash
# Ver log de Nextflow
cat .nextflow.log

# Ver logs de proceso específico
cat work/XX/XXXXXXXXXXXX/.command.log
```

---

## 📚 Más Información

- **Documentación Completa:** [README.md](../README.md)
- **Guía Docker/AWS:** [DOCKER_AWS_GUIDE.md](DOCKER_AWS_GUIDE.md)
- **Sistema de Reportes:** [REPORT_FEATURE.md](REPORT_FEATURE.md)
- **Resumen de Implementación:** [IMPLEMENTATION_SUMMARY.md](../IMPLEMENTATION_SUMMARY.md)

---

## 💡 Tips

1. **Siempre usar `-resume`** para ahorrar tiempo en re-ejecuciones
2. **Generar reporte (`--report`)** para análisis completo
3. **Verificar samplesheet** antes de ejecutar
4. **Monitorear recursos** durante ejecución
5. **Revisar logs** si hay errores

---

## 🆘 Obtener Ayuda

```bash
# Ver parámetros disponibles
nextflow run main.nf --help

# Ver versión
nextflow run main.nf --version
```

Para reportar issues:
- GitHub: https://github.com/leleonp/otuseq/issues

---

**Versión:** 2.12.0
**Última actualización:** 2025-12-30
