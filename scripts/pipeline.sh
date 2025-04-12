#--------------------------------------------------------
# Autora: Carmen Iborra
# Descripción: Decontamination of small-RNA sequencing samples from mouse
# Fecha: 2025-03-21
#--------------------------------------------------------

# Salir si algún comando falla
set -e

# -------------------------
# Step 1: Descarga de archivos
# -------------------------

#Download all the files specified in data/filenames
bash scripts/download.sh data/urls data #El script download.sh se encargará de descargar todos los archivos listados en data/urls

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh "https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz" res yes "small nuclear"

# -------------------------
# Step 2: Indexar contaminantes
# -------------------------

# Index the contaminants file
bash scripts/index.sh res/contaminants_seqkit.fasta res/contaminants_idx

# -------------------------
# Paso 3: Fusionar muestras
# -------------------------

# Merge the samples into a single file
for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | cut -d "/" -f2 | sort | uniq)
do
    echo "Processing sample $sid"
    bash scripts/merge_fastqs.sh data out/merged "$sid" 
done

# -------------------------
# Step 4: Recorte con cutadapt
# -------------------------

# Run cutadapt for all merged files
# Asegurarse de que los directorios de salida existen
mkdir -p out/trimmed
mkdir -p log/cutadapt

# Recorrer todos los archivos merged.fastq.gz
for file in out/merged/*.fastq.gz
do
    # Obtener el ID de archivo (sin la extensión .merged.fastq.gz)
    sid=$(basename "$file" .merged.fastq.gz)

    # Comprobar si el archivo ya fue recortado
    if [ -e "out/trimmed/$sid.trimmed.fastq.gz" ]
    then
        echo "El archivo out/trimmed/$sid.trimmed.fastq.gz ya existe. Omitiendo."
    else
        echo "Ejecutando cutadapt en $sid..."
        cutadapt -m 18 \
            -a TGGAATTCTCGGGTGCCAAGG \
            --discard-untrimmed \
            -o "out/trimmed/$sid.trimmed.fastq.gz" "$file" > "log/cutadapt/$sid.log"
    fi
done

# -------------------------
# Step 5: Alineamiento con STAR
# -------------------------

# Run STAR for all trimmed files
# crear el directrio de logs si no existe
mkdir -p log/star

#Bucle sobre los archivos con lecturas recortadas
for fname in out/trimmed/*.fastq.gz 
do
    sid=$(basename "$fname" .trimmed.fastq.gz) 
    if [ -e "out/star/$sid/Aligned.out.sam" ] #Si el sam de alineamiento de la muestra existe, mostramos un mensaje de advertencia.
    then
        echo "$sid ya está alineado. Se omite."
    else
        echo "Alineando muestra: $sid"

        #creamos el directorio de salida para la muestra.
        mkdir -p out/star/$sid 

        #ejecutamos STAR
        STAR --runThreadN 4 \
        --genomeDir res/contaminants_idx/ \
        --outReadsUnmapped Fastx \
        --readFilesIn "$fname" \
        --readFilesCommand gunzip -c \
        --outFileNamePrefix "out/star/$sid/" 

        # Verificar si STAR terminó bien
        if [ $? -eq 0 ]; then
            echo "Alineamiento realizado correctamente: $sid"
        else
            echo "Error: STAR falló para la muestra $sid."
            exit 1
        fi
    fi
done 

# -------------------------
# Step 6: Crear log general
# -------------------------

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

# Ruta del log general
cutadapt_star_log="log/pipeline_general.log"

# Crear encabezado si el log no existe aún
if [ ! -f "$cutadapt_star_log" ]
then
    {
        echo "GENERAL LOG FOR CUTADAPT AND STAR"
        echo ""
        echo "__________________________________"
    } > "$cutadapt_star_log"
fi

# Añadir sección para CUTADAPT
{
    echo ""
    echo "CUTADAPT Alignment Log"
} >> "$cutadapt_star_log"

# Bucle sobre cada archivo de cutadapt
for cutadapt_log in log/cutadapt/*.log
do
    sid=$(basename "$cutadapt_log" .log)

    # Añadir información de cutadapt
    {
        echo ""
        echo "Sample: $sid"
        grep "Reads with adapters" "$cutadapt_log"
        grep "Total basepairs" "$cutadapt_log"
    } >> "$cutadapt_star_log"
done

# Añadir sección para STAR
{
    echo ""
    echo " STAR Alignment Summary Log "
} >> "$cutadapt_star_log"

# Bucle sobre cada archivo STAR Log.final.out
for star_log in out/star/*/Log.final.out; do
    sid=$(basename "$(dirname "$star_log")")

    {
        echo ""
        echo "Sample: $sid"
        grep "Uniquely mapped reads %" "$star_log"
        grep "% of reads mapped to multiple loci" "$star_log"
        grep "% of reads mapped to too many loci" "$star_log"
    } >> "$cutadapt_star_log"
done

# -------------------------
# Mensaje final
# -------------------------

echo -e "\n\033[1;32m Pipeline completado.\033[0m Revisa 'log/pipeline_general.log' para el resumen."
