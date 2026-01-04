#!/bin/bash

filename=$1

arrkeys=()
arrvalues=()
ok=0
dupe=0

if [ ! -f "$filename" ]
then
    echo "File does not exist or it exists in a different directory."
    exit 0
else

    while read key value rest_of_line
    do
        if [[ -z $key || $key == "#"* ]]
        then
            continue
        fi

        arrkeys+=("$key")
        arrvalues+=("$value")

    done < "$filename"
fi

nr_keys=${#arrkeys[@]}

for ((i=0;i<nr_keys;i++))
do
    for ((j=i+1; j<nr_keys; j++))
    do 
        if [[ ${arrkeys[$i]} == ${arrkeys[$j]} ]]
        then
            echo "Duplicate key in file: '${arrkeys[$i]}', first value is '${arrvalues[$i]}'."
            unset arrkeys[$j]
            arrkeys=(${arrkeys[@]})
            unset arrvalues[$j]
            arrvalues=(${arrvalues[@]})
            ((nr_keys--))
            ok=1
        fi
    done

    if [[ ${arrkeys[$i]} == "PermitRootLogin" && ${arrvalues[$i]} != "no" ]]
    then  
        echo "Critical: PermitRootLogin must be 'no'."
        ok=1
    fi

    if [[ ${arrkeys[$i]} == "PasswordAuthentication" && ${arrvalues[$i]} != "no" ]]
    then
        echo "Warning: PasswordAuthentication should be 'no', SSH keys are much safer."
        ok=1
    fi

    if [[ ${arrkeys[$i]} == "X11Forwarding" && ${arrvalues[$i]} != "no" ]]
    then
        echo "X11Forwarding should be 'no'."
        ok=1
    fi

    if [[ ${arrkeys[$i]} == "Protocol" && ${arrvalues[$i]} == 1 ]]
    then
        echo "Critical: Protocol version must not be '1' as it's no longer safe."
        ok=1
    fi
    
    if [[ ${arrkeys[$i]} == "PermitEmptyPasswords" && ${arrvalues[$i]} != 'no' ]]
    then
        echo "Warning: PermitEmptyPasswords should be 'no' for safety reasons."
        ok=1
    fi

    if [[ ${arrkeys[$i]} == "MaxAuthTries" && ${arrvalues[$i]} -gt 4 ]]
    then 
        echo "Warning: MaxAuthTries shouldn't be over 4 for safety reasons."
        ok=1
    fi

done

if (( $ok == 0 ))
then
    echo "The file doesn't have any errors."
fi

exit 0