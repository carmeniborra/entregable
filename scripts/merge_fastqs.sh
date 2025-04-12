# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).

#!/bin/bash

# Verificar que se han proporcionado los tres argumentos necesarios
if [ $# -ne 3 ]; then
  echo "Error: Número incorrecto de argumentos."
  echo "Argumentos requeridso: $0 <samples_directory> <output_directory> <sample_id>"
  exit 1
fi

# argumentos
samples_directory="$1"
output_directory="$2"
sample_id="$3"

# Verificar que el directorio de muestras existe
if [ ! -d "$samples_directory" ]; then
  echo "Error: El directorio de muestras no existe: $samples_directory"
  exit 1
fi

# crear el directorio de salida si no existe
mkdir -p "$output_directory"

# Crear el nombre del archivo de salida basado en el sample_id
output_file="${output_directory}/${sample_id}_merged.txt"

# Fusionar todos los archivos que contienen el sample_id en su nombre
cat "$samples_directory"/*"$sample_id"* > "$output_file"

# Verificar si la fusión fue exitosa
if [ $? -eq 0 ]; then
  echo "Los archivos de la muestra $sample_id han sido fusionados exitosamente en: $output_file"
else
  echo "Error: No se pudieron fusionar los archivos de la muestra $sample_id"
  exit 1
fi
