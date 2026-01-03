#!/bin/bash

filename=$1

arrkeys=()
arrvalues=()

if [ ! -e "$filename" ]
then
    echo "File does not exist or it exists in a different directory."
else

    while read key value rest_of_line
    do
        if [[ -z $key || $key=="#"* ]]
        then
            continue
        fi

        arrkeys+=( "$key" )
        arrvalues+=( "$value" )

    done < "$filename"

fi

exit 0