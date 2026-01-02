#!/bin/bash

################################################################################
# Script de Lanzamiento para Docker - OTUseq Pipeline
################################################################################
#
# Este script facilita la ejecución del pipeline OTUseq con Docker
#
# Uso:
#   ./bin/run_docker.sh [OPTIONS]
#
# Ejemplo:
#   ./bin/run_docker.sh \
#       --input samples.csv \
#       --outdir results \
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
INPUT=""
OUTDIR="results"
REPORT=""
RESUME=""
ARM_PLATFORM=""

# Función de ayuda
usage() {
    cat << EOF
Uso: $0 [OPTIONS]

Opciones requeridas:
    --input PATH           Samplesheet (CSV)

Opciones opcionales:
    --outdir PATH          Directorio de salida (default: results)
    --report               Generar reporte HTML
    --resume               Reanudar ejecución previa
    --arm                  Usar plataforma ARM (Mac M1/M2/M3)
    --help                 Mostrar esta ayuda

Parámetros adicionales del pipeline:
    --forward-primer STR   Primer forward (default: CCTAYGGGRBGCASCAG)
    --reverse-primer STR   Primer reverse (default: GGACTACNNGGGTATCTAAT)
    --min-length INT       Longitud mínima de secuencias (default: 200)
    --perc-identity FLOAT  Identidad para clustering (default: 0.97)

Ejemplos:
    # Ejecución básica
    $0 --input samples.csv

    # Con reporte
    $0 --input samples.csv --outdir mis_resultados --report

    # En Mac con Apple Silicon
    $0 --input samples.csv --report --arm

    # Personalizado con parámetros
    $0 --input samples.csv \\
       --outdir results_custom \\
       --min-length 250 \\
       --perc-identity 0.99 \\
       --report \\
       --resume

EOF
    exit 1
}

# Parsear argumentos
EXTRA_PARAMS=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT="$2"
            shift 2
            ;;
        --outdir)
            OUTDIR="$2"
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
        --arm)
            ARM_PLATFORM=",arm"
            shift
            ;;
        --forward-primer|--reverse-primer|--min-length|--perc-identity)
            EXTRA_PARAMS="$EXTRA_PARAMS $1 $2"
            shift 2
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
if [ -z "$INPUT" ]; then
    echo -e "${RED}Error: --input es requerido${NC}"
    usage
fi

# Verificar que el archivo de input existe
if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: Archivo de input no encontrado: $INPUT${NC}"
    exit 1
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker no está instalado${NC}"
    echo "Instalar desde: https://docs.docker.com/get-docker/"
    exit 1
fi

# Verificar que Docker está corriendo
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Docker no está corriendo${NC}"
    echo "Iniciar Docker Desktop o el daemon de Docker"
    exit 1
fi

# Verificar Nextflow
if ! command -v nextflow &> /dev/null; then
    echo -e "${RED}Error: Nextflow no está instalado${NC}"
    echo "Instalar con: curl -s https://get.nextflow.io | bash"
    exit 1
fi

# Crear directorio de salida si no existe
mkdir -p "$OUTDIR"

# Detectar plataforma automáticamente
if [ -z "$ARM_PLATFORM" ]; then
    if [ "$(uname -m)" = "arm64" ]; then
        echo -e "${YELLOW}Detectada plataforma ARM, usando --platform=linux/amd64${NC}"
        ARM_PLATFORM=",arm"
    fi
fi

# Mostrar configuración
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  OTUseq Pipeline - Ejecución con Docker${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Configuración:${NC}"
echo "  Input:            $INPUT"
echo "  Output:           $OUTDIR"
echo "  Perfil:           docker${ARM_PLATFORM}"
echo "  Reporte:          $([ -n "$REPORT" ] && echo 'SÍ' || echo 'NO')"
echo "  Resume:           $([ -n "$RESUME" ] && echo 'SÍ' || echo 'NO')"
if [ -n "$EXTRA_PARAMS" ]; then
    echo "  Parámetros extra: $EXTRA_PARAMS"
fi
echo ""

# Verificar espacio en disco
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo -e "${YELLOW}Espacio disponible en disco: $AVAILABLE_SPACE${NC}"
echo ""

# Confirmar ejecución
read -p "¿Continuar con la ejecución? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo -e "${YELLOW}Ejecución cancelada${NC}"
    exit 0
fi

# Ejecutar pipeline
echo -e "${GREEN}Iniciando pipeline...${NC}"
echo ""

# Construir comando
CMD="nextflow run main.nf \
    --input \"$INPUT\" \
    --outdir \"$OUTDIR\" \
    $REPORT \
    $EXTRA_PARAMS \
    -profile docker${ARM_PLATFORM} \
    $RESUME \
    -ansi-log true"

# Ejecutar
eval $CMD

EXIT_CODE=$?

# Mostrar resultado
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}  Pipeline completado exitosamente!${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo ""
    echo "Resultados disponibles en: $OUTDIR"
    echo ""

    if [ -n "$REPORT" ]; then
        REPORT_FILE="$OUTDIR/report/OTUseq_Report.html"
        if [ -f "$REPORT_FILE" ]; then
            echo -e "${GREEN}Reporte HTML generado:${NC}"
            echo "  $REPORT_FILE"
            echo ""
            echo "Abrir reporte:"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "  open $REPORT_FILE"
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                echo "  xdg-open $REPORT_FILE"
            else
                echo "  Abrir en navegador: file://$(realpath $REPORT_FILE)"
            fi
            echo ""
        fi
    fi

    echo "Archivos principales:"
    echo "  - Tablas Excel:        $OUTDIR/abundance_tables/"
    echo "  - Gráficos:            $OUTDIR/taxonomy_plots/"
    echo "  - Diversidad Alfa:     $OUTDIR/alpha_diversity/"
    echo "  - Diversidad Beta:     $OUTDIR/beta_diversity/"
    echo "  - Curvas Rarefacción:  $OUTDIR/rarefaction/"
    echo ""
else
    echo -e "${RED}==================================================${NC}"
    echo -e "${RED}  Pipeline falló con código: $EXIT_CODE${NC}"
    echo -e "${RED}==================================================${NC}"
    echo ""
    echo "Para ver logs detallados:"
    echo "  cat .nextflow.log"
    echo ""
    echo "Para reintentar con -resume:"
    echo "  $0 --input $INPUT --outdir $OUTDIR $REPORT --resume"
    echo ""
fi

exit $EXIT_CODE
