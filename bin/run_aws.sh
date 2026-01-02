#!/bin/bash

################################################################################
# Script de Lanzamiento para AWS Batch - OTUseq Pipeline
################################################################################
#
# Este script facilita la ejecución del pipeline OTUseq en AWS Batch
#
# Uso:
#   ./bin/run_aws.sh [OPTIONS]
#
# Ejemplo:
#   ./bin/run_aws.sh \
#       --project GM2025_001 \
#       --input s3://genomamayor/GM2025_001/samplesheet.csv \
#       --report
#
################################################################################

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Valores por defecto
BUCKET="${AWS_BUCKET:-s3://genomamayor}"
REGION="${AWS_REGION:-us-east-1}"
QUEUE="${AWS_BATCH_QUEUE:-default}"
PROJECT=""
INPUT=""
OUTDIR=""
REPORT=""
RESUME=""

# Función de ayuda
usage() {
    cat << EOF
Uso: $0 [OPTIONS]

Opciones requeridas:
    --project PROJECT       Nombre del proyecto
    --input PATH           Samplesheet (s3:// o local)

Opciones opcionales:
    --bucket BUCKET        Bucket S3 (default: s3://genomamayor)
    --outdir PATH          Directorio de salida (default: s3://BUCKET/PROJECT/results_FECHA)
    --region REGION        Región AWS (default: us-east-1)
    --queue QUEUE          Cola AWS Batch (default: default)
    --report               Generar reporte HTML
    --resume               Reanudar ejecución previa
    --help                 Mostrar esta ayuda

Ejemplos:
    # Ejecución básica
    $0 --project GM2025_001 --input samples.csv

    # Con reporte y resume
    $0 --project GM2025_001 --input s3://mi-bucket/samples.csv --report --resume

    # Personalizado
    $0 --project TEST_001 \\
       --input data/samples.csv \\
       --bucket s3://mi-bucket-custom \\
       --region us-west-2 \\
       --queue high-priority \\
       --report

Variables de entorno:
    AWS_BUCKET             Bucket S3 por defecto
    AWS_REGION             Región AWS por defecto
    AWS_BATCH_QUEUE        Cola AWS Batch por defecto

EOF
    exit 1
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --input)
            INPUT="$2"
            shift 2
            ;;
        --bucket)
            BUCKET="$2"
            shift 2
            ;;
        --outdir)
            OUTDIR="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --queue)
            QUEUE="$2"
            shift 2
            ;;
        --report)
            REPORT="--report"
            shift
            ;;
        --resume)
            RESUME="-resume"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            usage
            ;;
    esac
done

# Validar argumentos requeridos
if [ -z "$PROJECT" ]; then
    echo -e "${RED}Error: --project es requerido${NC}"
    usage
fi

if [ -z "$INPUT" ]; then
    echo -e "${RED}Error: --input es requerido${NC}"
    usage
fi

# Configurar directorio de salida si no se especificó
if [ -z "$OUTDIR" ]; then
    DATE=$(date +%Y%m%d_%H%M%S)
    OUTDIR="${BUCKET}/${PROJECT}/results_${DATE}"
fi

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI no está instalado${NC}"
    echo "Instalar con: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Verificar Nextflow
if ! command -v nextflow &> /dev/null; then
    echo -e "${RED}Error: Nextflow no está instalado${NC}"
    echo "Instalar con: curl -s https://get.nextflow.io | bash"
    exit 1
fi

# Verificar credenciales AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: Credenciales AWS no configuradas${NC}"
    echo "Configurar con: aws configure"
    exit 1
fi

# Mostrar configuración
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  OTUseq Pipeline - Lanzamiento en AWS Batch${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Configuración:${NC}"
echo "  Proyecto:         $PROJECT"
echo "  Input:            $INPUT"
echo "  Output:           $OUTDIR"
echo "  Bucket:           $BUCKET"
echo "  Región:           $REGION"
echo "  Cola:             $QUEUE"
echo "  Work directory:   ${BUCKET}/work"
echo "  Reporte:          $([ -n "$REPORT" ] && echo 'SÍ' || echo 'NO')"
echo "  Resume:           $([ -n "$RESUME" ] && echo 'SÍ' || echo 'NO')"
echo ""

# Confirmar ejecución
read -p "¿Continuar con la ejecución? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo -e "${YELLOW}Ejecución cancelada${NC}"
    exit 0
fi

# Crear configuración temporal de AWS
TMP_AWS_CONFIG=$(mktemp)
cat > "$TMP_AWS_CONFIG" << EOF
aws {
    region = '$REGION'
    batch {
        cliPath = '/home/ec2-user/miniconda/bin/aws'
        maxTransferAttempts = 3
        delayBetweenAttempts = '5 sec'
    }
}

process {
    executor = 'awsbatch'
    queue = '$QUEUE'
}

workDir = '${BUCKET}/work'

aws.client.uploadChunkSize = '100MB'
aws.client.uploadMaxThreads = 8
aws.client.uploadStorageClass = 'INTELLIGENT_TIERING'
EOF

# Ejecutar pipeline
echo -e "${GREEN}Iniciando pipeline...${NC}"
echo ""

nextflow run main.nf \
    --input "$INPUT" \
    --outdir "$OUTDIR" \
    --ref_database "${BUCKET}/databases/silva/silva138_AB_V3-V4_classifier.qza" \
    $REPORT \
    -profile aws_batch \
    -c "$TMP_AWS_CONFIG" \
    -work-dir "${BUCKET}/work" \
    $RESUME \
    -ansi-log true

EXIT_CODE=$?

# Limpiar archivo temporal
rm -f "$TMP_AWS_CONFIG"

# Mostrar resultado
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}  Pipeline completado exitosamente!${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo ""
    echo "Resultados disponibles en: $OUTDIR"
    echo ""
    echo "Para descargar resultados:"
    echo "  aws s3 sync $OUTDIR ./resultados_locales/"
    echo ""
    if [ -n "$REPORT" ]; then
        echo "Reporte HTML:"
        echo "  aws s3 cp ${OUTDIR}/report/OTUseq_Report.html ."
        echo ""
    fi
else
    echo -e "${RED}==================================================${NC}"
    echo -e "${RED}  Pipeline falló con código: $EXIT_CODE${NC}"
    echo -e "${RED}==================================================${NC}"
    echo ""
    echo "Para reintentar con -resume:"
    echo "  $0 $(echo "$@" | sed 's/--resume//g') --resume"
    echo ""
fi

exit $EXIT_CODE
