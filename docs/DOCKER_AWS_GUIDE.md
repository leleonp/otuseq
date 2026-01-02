# Guía de Uso: Docker y AWS - OTUseq Pipeline

## 📋 Resumen

El pipeline OTUseq está completamente preparado para ejecutarse en:
- ✅ **Docker** (local o servidor)
- ✅ **AWS Batch** (computación en la nube)
- ✅ **Contenedores públicos** (AWS ECR y community.wave.seqera.io)

---

## 🐳 Ejecución con Docker (Local)

### Requisitos Previos

1. **Docker instalado**
   ```bash
   docker --version
   # Docker version 20.10.0 o superior
   ```

2. **Nextflow instalado**
   ```bash
   curl -s https://get.nextflow.io | bash
   sudo mv nextflow /usr/local/bin/
   ```

### Uso Básico

```bash
# Análisis básico con Docker
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    -profile docker

# Con generación de reporte
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --report \
    -profile docker
```

### Configuración de Docker

El perfil `docker` está configurado en [nextflow.config:73-82](../nextflow.config#L73-L82):

```groovy
docker {
    docker.enabled          = true
    docker.runOptions       = '-u $(id -u):$(id -g)'
}
```

### Para Mac con Apple Silicon (M1/M2/M3)

Si usas Mac con chip ARM, usa el perfil `arm`:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    -profile docker,arm
```

Este perfil configura:
```groovy
docker.runOptions = '-u $(id -u):$(id -g) --platform=linux/amd64'
```

---

## ☁️ Ejecución en AWS Batch

### Requisitos Previos

#### 1. Configurar AWS CLI

```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
# AWS Access Key ID: [TU_ACCESS_KEY]
# AWS Secret Access Key: [TU_SECRET_KEY]
# Default region name: us-east-1
# Default output format: json
```

#### 2. Configurar AWS Batch

Necesitas tener configurado:
- **Compute Environment** (ambiente de cómputo)
- **Job Queue** (cola de trabajos)
- **S3 Bucket** para trabajo y resultados

#### 3. Permisos IAM Requeridos

Tu usuario/rol necesita permisos para:
- AWS Batch (SubmitJob, DescribeJobs, etc.)
- S3 (ListBucket, GetObject, PutObject, etc.)
- CloudWatch Logs (lectura)
- EC2 (si creas instancias)

### Personalizar Configuración AWS

Edita el archivo [conf/aws.config](../conf/aws.config) con tus valores:

```groovy
aws {
    region = 'us-east-1'  // Cambiar a tu región
    batch {
        cliPath = '/home/ec2-user/miniconda/bin/aws'
    }
}

process {
    executor = 'awsbatch'
    queue = 'mi-cola-otuseq'  // Cambiar al nombre de tu cola
}

workDir = 's3://mi-bucket/work'  // Cambiar a tu bucket
```

### Uso en AWS Batch

```bash
# Ejecutar en AWS Batch
nextflow run main.nf \
    --input s3://mi-bucket/input/samplesheet.csv \
    --outdir s3://mi-bucket/results \
    --report \
    -profile aws_batch

# Usar bases de datos de S3
nextflow run main.nf \
    --input s3://mi-bucket/input/samplesheet.csv \
    --ref_database s3://genomamayor/GM1621_3/silva/silva138_AB_V3-V4_classifier.qza \
    --outdir s3://mi-bucket/results \
    -profile aws_batch
```

### Monitoreo en AWS

```bash
# Ver estado del trabajo
aws batch describe-jobs --jobs <JOB_ID>

# Ver logs en CloudWatch
aws logs tail /aws/batch/job --follow
```

---

## 📦 Contenedores Utilizados

### Contenedores Públicos en AWS ECR

Todos los contenedores principales están alojados en AWS ECR público:

| Proceso | Contenedor | Ubicación |
|---------|-----------|-----------|
| QIIME2 (mayoría) | `public.ecr.aws/b1n7j4p9/qiime2:2023.2` | AWS ECR |
| FastQC | `public.ecr.aws/biocontainers/fastqc:0.12.1` | AWS ECR |
| MultiQC | `public.ecr.aws/biocontainers/multiqc:1.26` | AWS ECR |
| Cutadapt | `public.ecr.aws/biocontainers/cutadapt:4.9` | AWS ECR |

### Contenedores en Seqera Wave

Algunos procesos especializados usan Seqera Wave:

| Proceso | Contenedor |
|---------|-----------|
| REMOVE_HOMOPOLYMERS | `community.wave.seqera.io/library/biopython_pandas` |
| EXPORT_TO_EXCEL | `community.wave.seqera.io/library/pandas_openpyxl_biom-format` |
| TAXONOMY_PLOTS | `community.wave.seqera.io/library/pandas_matplotlib_seaborn_biom-format` |
| RAREFACTION_PLOTS | `community.wave.seqera.io/library/pandas_matplotlib_seaborn_openpyxl` |

### Contenedor de Reportes

| Proceso | Contenedor | Descripción |
|---------|-----------|-------------|
| GENERATE_REPORT | `rocker/verse:latest` | R + Quarto + tidyverse |

---

## 🔧 Configuración Avanzada

### Ajustar Recursos por Proceso

En AWS, los recursos se configuran por labels en [conf/aws.config](../conf/aws.config):

```groovy
process {
    withLabel:process_low {
        cpus = 2
        memory = '12 GB'
    }

    withLabel:process_medium {
        cpus = 4
        memory = '32 GB'
    }

    withLabel:process_high {
        cpus = 16
        memory = '120 GB'
    }

    // Ajustar proceso específico
    withName:GENERATE_REPORT {
        memory = '16 GB'
        cpus = 4
    }
}
```

### Optimización de S3

El pipeline está configurado para optimizar transferencias S3:

```groovy
aws.client.uploadChunkSize = '100MB'
aws.client.uploadMaxThreads = 8
aws.client.uploadStorageClass = 'INTELLIGENT_TIERING'
```

---

## 📊 Samplesheet para S3

### Formato del Samplesheet

```csv
sample_id,forward,reverse
sample1,s3://mi-bucket/raw/sample1_R1.fastq.gz,s3://mi-bucket/raw/sample1_R2.fastq.gz
sample2,s3://mi-bucket/raw/sample2_R1.fastq.gz,s3://mi-bucket/raw/sample2_R2.fastq.gz
sample3,s3://mi-bucket/raw/sample3_R1.fastq.gz,s3://mi-bucket/raw/sample3_R2.fastq.gz
```

### Ejemplo con Rutas Locales (Docker)

```csv
sample_id,forward,reverse
sample1,/data/raw/sample1_R1.fastq.gz,/data/raw/sample1_R2.fastq.gz
sample2,/data/raw/sample2_R1.fastq.gz,/data/raw/sample2_R2.fastq.gz
sample3,/data/raw/sample3_R1.fastq.gz,/data/raw/sample3_R2.fastq.gz
```

---

## 🚀 Ejemplos Completos

### Ejemplo 1: Docker Local con Datos Locales

```bash
#!/bin/bash

# Ejecutar pipeline completo con Docker
nextflow run leleonp/otuseq \
    --input samples.csv \
    --outdir results_$(date +%Y%m%d) \
    --forward_primer 'CCTAYGGGRBGCASCAG' \
    --reverse_primer 'GGACTACNNGGGTATCTAAT' \
    --min_length 200 \
    --perc_identity 0.97 \
    --report \
    -profile docker \
    -resume
```

### Ejemplo 2: AWS Batch con Datos en S3

```bash
#!/bin/bash

# Configurar variables
BUCKET="s3://genomamayor"
PROJECT="GM2025_001"
DATE=$(date +%Y%m%d)

# Ejecutar en AWS Batch
nextflow run leleonp/otuseq \
    --input ${BUCKET}/${PROJECT}/samplesheet.csv \
    --outdir ${BUCKET}/${PROJECT}/results_${DATE} \
    --ref_database ${BUCKET}/databases/silva/silva138_AB_V3-V4_classifier.qza \
    --min_length 200 \
    --report \
    -profile aws_batch \
    -work-dir ${BUCKET}/work \
    -resume
```

### Ejemplo 3: Docker con Volúmenes Montados

```bash
#!/bin/bash

# Montar directorios locales
nextflow run main.nf \
    --input /mnt/data/samples.csv \
    --outdir /mnt/results \
    -profile docker \
    -with-docker "-v /mnt/data:/data:ro -v /mnt/results:/results:rw"
```

---

## 🔍 Troubleshooting

### Docker: Problemas de Permisos

**Problema:** Permission denied al escribir archivos

**Solución:**
```bash
# El pipeline usa automáticamente tu UID:GID
# Si tienes problemas, verifica:
id -u  # Tu User ID
id -g  # Tu Group ID

# Asegúrate de que los directorios de salida tengan permisos correctos
chmod -R 755 results/
```

### AWS: Fallo al Descargar Contenedores

**Problema:** Error pulling Docker image from ECR

**Solución:**
```bash
# Verificar que tu Compute Environment tiene permisos ECR
# Agregar política al rol de ejecución:
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ],
    "Resource": "*"
  }]
}
```

### AWS: Timeout en Transferencias S3

**Problema:** S3 upload timeout

**Solución:**
```bash
# Incrementar chunk size y threads en nextflow.config
aws.client.uploadChunkSize = '200MB'
aws.client.uploadMaxThreads = 16
```

### Contenedores Wave no Disponibles

**Problema:** Cannot pull from community.wave.seqera.io

**Solución:**
```bash
# Usar perfil wave para pull automático
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    -profile docker,wave
```

---

## 💰 Estimación de Costos AWS

### Costo Aproximado por Muestra

Para referencia (precios us-east-1, puede variar):

| Componente | Costo Estimado |
|-----------|---------------|
| EC2 Compute (Batch) | $0.50 - $2.00 / muestra |
| S3 Storage (temporal) | $0.023 / GB-mes |
| S3 Requests | $0.005 / 1000 requests |
| Data Transfer | $0.09 / GB (out) |

**Ejemplo:** 10 muestras, 50 GB datos totales
- Compute: ~$15
- Storage (1 mes): ~$1.15
- Total estimado: **~$16-20**

### Optimización de Costos

1. **Usar Spot Instances** en AWS Batch (70% descuento)
2. **Intelligent Tiering** para S3 (configurado por defecto)
3. **Limpiar work directory** después de ejecución exitosa
4. **Usar -resume** para re-ejecutar solo pasos fallidos

```bash
# Limpiar directorio de trabajo después de éxito
nextflow run main.nf ... && \
    aws s3 rm s3://mi-bucket/work --recursive
```

---

## 📚 Referencias Adicionales

### Documentación Oficial
- [Nextflow AWS Batch](https://www.nextflow.io/docs/latest/awscloud.html)
- [AWS Batch Documentation](https://docs.aws.amazon.com/batch/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Tutoriales
- [Setting up AWS Batch for Nextflow](https://nf-co.re/docs/usage/tutorials/aws_batch)
- [Nextflow on AWS](https://aws.amazon.com/blogs/compute/nextflow-integration-with-aws-batch/)

---

## ✅ Checklist de Pre-Ejecución

### Para Docker Local
- [ ] Docker instalado y funcionando
- [ ] Nextflow instalado (versión ≥24.04.2)
- [ ] Samplesheet preparado con rutas correctas
- [ ] Directorio de salida con permisos adecuados
- [ ] Espacio en disco suficiente

### Para AWS Batch
- [ ] AWS CLI configurado con credenciales
- [ ] Compute Environment creado
- [ ] Job Queue configurada
- [ ] S3 Bucket creado
- [ ] Permisos IAM correctos
- [ ] Región AWS configurada en `conf/aws.config`
- [ ] Work directory S3 especificado
- [ ] Samplesheet en S3 (opcional pero recomendado)

---

**Última actualización:** 2025-12-30
**Versión del pipeline:** 2.12.0
**Estado:** ✅ Listo para producción en Docker y AWS
