# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

#!/bin/bash (le indico al sistema que interprete el script con bash, no es neceario en este caso, pero es una buena práctica)

# Argumentos
url="$1"
dir="$2"
uncompress="$3"
filter="$4"

#con esta condición, se comprueba si el número de argumentos es 2 o 4, de esta forma, para desacrgar los archivos de urls, se dirige por la primera condición, y para descargar el archivo contaminants.fasta.gz, salta a la siguente.
if [ "$#" -eq 2 ] #Si se introducen dos argumentos (descarga de urls y directorio de destino):
then
    mkdir -p "$dir" #crear el directorio si no existe.
    if [ -e "$dir/urls" ] #Si el archivo ya existe, no lo descargamos de nuevo.
    then
        echo "The file $dir/urls exists" #Mensaje mostrando que el archivo ya existe.
    else
        echo "Downloading $url into "$dir"" #Mensaje mostrando que se va a descargar el archivo.
        wget -P "$dir" "https://github.com/bioinfo-lessons/decont/blob/master/data/urls" #Descarga del archivo urls de github.
    fi

    # Leer cada URL de data/urls
    while read -r url
    do
        # Definimos el nombre del archivo desde la URL 
        file_name=$(basename "$url")
        output_path="$dir/$file_name"
        
        # Comprobar si el archivo ya existe
        if [ -e "$output_path" ] 
        then
            echo "The file $file_name exists."
        else
            # Descargar el archivo
            echo "Downloading from "$url" into "$dir""
            wget -P "$dir" "$url" 

            #md5 esperado y calculado del archivo fasta sin descargarlo, y del archivo fasta descargado.
            esp_md5=$(wget -qO- "$url.md5" | awk '{print $url}')
            calc_md5=$(md5sum "$output_path" | awk '{print $url}')

            # Comprobar si el md5sum es correcto
            if [ "$esp_md5" == "$calc_md5" ]
            then
                echo "The md5sum of $file_name is correct" 
            else
                echo "The md5sum of $file_name is incorrect"
            fi
            echo "Procesamiento finalizado. Archivo en: $output_path" #mensaje mostrando que el procesamiento ha finalizado y la ruta del archivo.
        fi
    done < "$url" # con < "$url" leemos el archivo urls línea por línea.


elif [ "$#" -eq 4 ] #cuando hay cuatro argumentos, se descarga el archivo contaminants.fasta.gz y se descomprime.
then
    mkdir -p "$dir" #Crear el directorio si no existe.

    file_name=$(basename "$url") #Definimos el nombre del archivo desde la URL
    output_path="$dir/$file_name" #Definimos la ruta de salida del archivo.

    if [ -e "$output_path" ] #Si el archivo ya existe en el directorio de destino, muestro un mensaje de advertencia.
    then
        echo "The file $file_name exists."
    else
        echo "Downloading from "$url" into directory "$dir""
        wget -P "$dir" "$url" 

        #md5 esperado y calculado del archivo fasta sin descargarlo, y del archivo fasta descargado.
        exp_md5=$(wget -qO- "$url.md5" | awk '{print $url}')
        calc_md5=$(md5sum "$output_path" | awk '{print $url}')

        # Comprobar si el md5sum es correcto
        if [ "$exp_md5" == "$calc_md5" ] #Comparamos el md5 esperado con el md5 calculado.
        then
            echo "The md5sum of $file_name is correct" 
        else
            echo "The md5sum of $file_name is incorrect"
        fi

    fi

    #Comprobamos si el archivo contaminants.fasta.gz está comprimido, y si el tercer argumento es "yes", lo descomprimimos.
    if [[ "$uncompress" == "yes" && "$output_path" == *.gz ]] 
    then
        echo "Uncompressing the file "$file_name" into "$dir"" #Mensaje mostrando que se va a descomprimir el archivo.
        gunzip -k "$output_path" #con -k mantenemos el archivo original.
        echo "Uncompressed completed"
    else
        echo "file is not compressed" #si el archivo no está comprimido.
    fi

    # comprobamos el cuarto argumento, si no está vacío, filtramos el archivo fasta.
    if [ -n "$filter" ]
    then
        echo "Filtering "$filter""

        fasta_file=$(basename "$url" .gz)
        output_fasta="$dir/$fasta_file" #Defino la ruta de salida del archivo fasta.

        seqkit grep -v -r -i -n -p "$filter" "$output_fasta" -o "$dir/${fasta_file%.fasta}_seqkit.fasta" #Filtro con seqkit (paquete de bioconda) y guardo.

        echo "Filtering completed" 
    else
        echo "Filtering is not needed"
    fi

    echo "Procesamiento finalizado. Archivo en: $output_path" #mensaje mostrando que el procesamiento ha finalizado y la ruta del archivo.

#si no se introducen los argumentos correctos, se muestra un mensaje de error.
else
    echo "Error: Invalid number of arguments. Expected 2 or 4 arguments."
    exit 1
fi
