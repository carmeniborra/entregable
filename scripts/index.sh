# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

# STAR --runThreadN 4 --runMode genomeGenerate --genomeDir <outdir> \
# --genomeFastaFiles <genomefile> --genomeSAindexNbases 9

#!/bin/bash (le indico al sistema que interprete el script con bash, no es neceario en este caso, pero es una buena práctica)

# Verificar que se han proporcionado los argumentos necesarios
if [ $# -ne 2 ]
then
  echo "Error: Número incorrecto de argumentos"
  echo "Argumentos requeridos: $0 <genomefile> <outdir>"
  exit 1
fi

# Variables
genomefile="$1"
outdir="$2"

# Verificar que el archivo de genoma existe
if [ ! -f "$genomefile" ] # con ! indicamos negación
then
  echo "El archivo de genoma no existe: $genomefile"
  exit 1
fi

# crear el directorio de salida si no existe
mkdir -p "$outdir"

# Verificar si el índice ya existe (comprobando algunos archivos típicos de STAR)
if [ -f "$outdir/SA" ] 
then
  echo "El índice del genoma ya existe en: $outdir, no se genera de nuevo. Si desea regenerarlo, elimine el directorio de salida."
#Ejecutar el comando STAR para generar el índice del genoma
else
  echo "Generando índice del genoma con STAR..."
  STAR --runThreadN 4 --runMode genomeGenerate --genomeDir "$outdir" \
  --genomeFastaFiles "$genomefile" --genomeSAindexNbases 9

  echo "Índice del genoma creado en: $outdir"
fi
