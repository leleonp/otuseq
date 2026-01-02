# Funcionalidad de Reportes Automáticos - OTUseq Pipeline

## Descripción General

El pipeline OTUseq ahora incluye una funcionalidad de generación automática de reportes comprensivos en formato HTML utilizando Quarto (`.qmd`). Esta característica genera un reporte completo en español con todas las métricas, gráficos y tablas del análisis.

## Activación del Reporte

Para generar el reporte automático, simplemente agrega el parámetro `--report` al ejecutar el pipeline:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --report \
    -profile docker
```

## Contenido del Reporte

El reporte HTML generado (`OTUseq_Report.html`) incluye las siguientes secciones:

### 1. **Resumen Ejecutivo**
Descripción general del análisis y principales métricas

### 2. **Control de Calidad**
- ✅ Resumen de métricas FastQC
- ✅ Estadísticas de trimming con Cutadapt
- ✅ Tabla interactiva con métricas de calidad por muestra

### 3. **Seguimiento de Lecturas (Read Tracking)**
- ✅ Tabla detallada de lecturas en cada paso del pipeline:
  - Secuencias crudas
  - Después de filtrado de homopolímeros
  - Después de filtrado de bases ambiguas (N)
  - Después de trimming de primers
  - Después de merge de paired-end
  - Después de deduplicación
  - Después de clustering (OTUs 97%)
  - Después de eliminación de quimeras
  - Después de filtrado de taxa

### 4. **Curvas de Rarefacción**
- ✅ Gráficos de curvas de rarefacción para:
  - Shannon diversity
  - Chao1
  - Observed features
  - ACE
- ✅ Interpretación de resultados
- ✅ Visualizaciones en alta resolución (PDF/PNG)

### 5. **Diversidad Alfa**
- ✅ Tabla interactiva con índices de diversidad:
  - **Shannon:** Diversidad considerando riqueza y equitabilidad
  - **Chao1:** Estimador de riqueza de especies
  - **ACE:** Estimador basado en cobertura de abundancia
  - **Simpson:** Índice de dominancia
  - **Observed Features:** Número de OTUs observados
- ✅ Boxplots comparativos por métrica
- ✅ Estadísticas descriptivas

### 6. **Diversidad Beta**
- ✅ Información sobre métricas calculadas:
  - Bray-Curtis dissimilarity
  - Jaccard distance
  - Weighted UniFrac (filogenético)
  - Unweighted UniFrac (filogenético)
- ✅ Referencia a matrices de distancia y coordenadas PCoA

### 7. **Composición Taxonómica**
- ✅ Histogramas de abundancia relativa por nivel taxonómico:
  - **Nivel 2:** Phylum (Top 20)
  - **Nivel 3:** Clase (Top 20)
  - **Nivel 4:** Orden (Top 20)
  - **Nivel 5:** Familia (Top 20)
  - **Nivel 6:** Género (Top 20)
- ✅ Gráficos de barras en alta resolución
- ✅ Abundancias absolutas y relativas

### 8. **Tablas de Abundancia**
- ✅ Tablas interactivas (DataTables) para cada nivel taxonómico:
  - Phylum
  - Clase
  - Familia
  - Género
- ✅ Datos en formato Excel importados directamente
- ✅ Abundancia relativa (%) con formato de 2 decimales
- ✅ Funcionalidad de búsqueda y filtrado

### 9. **OTUs Representativos**
- ✅ Información sobre OTUs mayoritarios
- ✅ Referencias a archivos Excel con datos completos

### 10. **Árbol Filogenético**
- ✅ Descripción de archivos generados
- ✅ Enlaces para visualización en QIIME2 View

### 11. **Parámetros del Pipeline**
- ✅ Configuración completa del análisis:
  - Primers utilizados
  - Base de datos (SILVA 138)
  - Identidad de clustering
  - Longitud mínima
  - Filtros aplicados
  - Método de detección de quimeras

### 12. **Conclusiones y Recomendaciones**
- ✅ Resumen de hallazgos
- ✅ Próximos pasos sugeridos para análisis adicionales

### 13. **Información de la Sesión**
- ✅ Versiones de paquetes R utilizados
- ✅ Información del sistema

### 14. **Referencias**
- ✅ Citas bibliográficas de las herramientas utilizadas

## Estructura del Reporte

El reporte se genera en formato HTML auto-contenido (`embed-resources: true`), lo que significa que:
- ✅ Todas las imágenes están incrustadas
- ✅ No requiere archivos externos
- ✅ Puede compartirse como un único archivo
- ✅ Se puede abrir en cualquier navegador web

## Características Técnicas

### Template Quarto
- **Ubicación:** `assets/templates/report_template.qmd`
- **Formato:** HTML con tema Cosmo
- **Tabla de contenidos:** Lateral, con 3 niveles de profundidad
- **Gráficos:** Interactivos usando Plotly
- **Tablas:** Interactivas usando DT (DataTables)

### Contenedor Docker
- **Imagen:** `rocker/verse:latest`
- **Incluye:**
  - R con Quarto
  - Todas las librerías necesarias para análisis
  - Paquetes para visualización (ggplot2, plotly)
  - Paquetes para manejo de datos (dplyr, tidyr)

### Paquetes R Requeridos
```r
- knitr
- rmarkdown
- dplyr
- ggplot2
- tidyr
- kableExtra
- plotly
- DT
- scales
- readr
- jsonlite
- readxl
```

## Ubicación del Reporte

El reporte generado se publica en:
```
results/
└── report/
    ├── OTUseq_Report.html          # Reporte principal
    └── OTUseq_Report_files/        # Archivos auxiliares (si existen)
```

## Personalización

### Modificar el Template
Puedes personalizar el reporte editando el archivo:
```
assets/templates/report_template.qmd
```

### Parámetros Disponibles
El template acepta los siguientes parámetros (definidos en el módulo):
```yaml
params:
  project_name: "Análisis Microbioma OTUseq"
  outdir: "."
```

## Ejemplo de Uso Completo

```bash
# Análisis completo con generación de reporte
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results_proyecto_X \
    --forward_primer 'CCTAYGGGRBGCASCAG' \
    --reverse_primer 'GGACTACNNGGGTATCTAAT' \
    --min_length 200 \
    --perc_identity 0.97 \
    --report \
    -profile docker \
    -resume
```

## Solución de Problemas

### El reporte no se genera

**Problema:** El parámetro `--report` está en `false`
**Solución:**
```bash
--report  # o --report true
```

### Faltan datos en el reporte

**Problema:** Algunos módulos no completaron exitosamente
**Solución:**
- Verifica que todos los pasos del pipeline completaron sin errores
- Revisa los logs de Nextflow
- Ejecuta con `-resume` si es una re-ejecución

### Error de paquetes R

**Problema:** Faltan paquetes R en el contenedor
**Solución:**
- El módulo instala automáticamente los paquetes faltantes
- Verifica la conexión a internet del contenedor
- Considera pre-instalar paquetes en una imagen personalizada

## Visualización del Reporte

El reporte HTML puede visualizarse:
1. **Localmente:** Abre `OTUseq_Report.html` en cualquier navegador
2. **En servidor:** Despliega en un servidor web
3. **Compartir:** Envía el archivo HTML directamente (auto-contenido)

## Ventajas del Sistema de Reportes

✅ **Automatización completa:** Un solo comando genera todo el análisis
✅ **Formato profesional:** Reporte en español con diseño moderno
✅ **Interactividad:** Tablas y gráficos interactivos
✅ **Reproducibilidad:** Todos los parámetros documentados
✅ **Compartible:** Archivo único auto-contenido
✅ **Completo:** Incluye todas las métricas requeridas
✅ **Actualizable:** Template modificable según necesidades

## Próximas Mejoras

Posibles mejoras futuras para el sistema de reportes:

- [ ] Gráficos PCoA interactivos para diversidad beta
- [ ] Comparaciones estadísticas automáticas entre grupos
- [ ] Integración con metadatos de muestras
- [ ] Sección de análisis funcional (si se implementa)
- [ ] Export a formato PDF además de HTML
- [ ] Personalización de logos y branding
- [ ] Múltiples idiomas (inglés/español)

---

**Documentación actualizada:** 2025-12-30
**Versión del pipeline:** 2.12.0
