#!/bin/bash

if systemctl is-active --quiet ssh; then
    echo "SSH Daemon is running."            #verificare daca daemonul de ssh este activ
    echo 

    filename=$1
    if [[ -z $filename ]]
    then    
        echo "No file specified."   #verifica daca s-a introdus un argument
        exit 0
    fi

    arrkeys=()
    arrvalues=()
    ok=0
    must_keys=("PermitRootLogin" "PasswordAuthentication" "PubkeyAuthentication" "PermitEmptyPasswords" "MaxAuthTries" "LoginGraceTime" "StrictModes" "IgnoreRhosts" "HostbasedAuthentication")
    

    if [[ $filename != *"/"* ]]
    then
        filename=$(find / -name "$1" -type f 2>/dev/null | head -n 1)      #se cauta path-ul fisierului daca argumentul primit nu este deja un path
    fi

    if [[ ! -f $filename ]]
    then 
        echo "File doesn't exist."
        exit 0
    else 
        file_perms=$(stat -c %a "$filename")

        #echo "DEBUG: fisierul verifcat este '$filename'"
        #echo "Permisiunile reale sunt: $file_perms"      
        #echo

        if [[ "$file_perms" == "600" || "$file_perms" == "644" ]]
        then   
            
            while read key value rest_of_line
            do
                if [[ -z $key || $key == "#"* ]]
                then
                    continue                             #introducerea valorilor in array-uri
                fi

                arrkeys+=("$key")
                arrvalues+=("$value")

            done < "$filename"


            nr_keys=${#arrkeys[@]}

            for keys in ${must_keys[@]}
            do  
                x=0
                for key in ${arrkeys[@]}
                do
                    if [[ $keys == $key ]]                #verificarea existentei cheilor importante
                    then
                            x=1
                            break
                    fi
                done
                if [[ $x -eq 0 ]]
                then
                    echo "Critical: There is no '$keys' key in the file."
                    ok=1
                fi
            done 


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
                        arrvalues=(${arrvalues[@]})              #verificarea duplicatelor si stergerea acestora din array
                        ((nr_keys--))
                        ok=1
                    fi
                done
            done

            echo
            echo "All the duplicates have been deleted"
            echo

            for ((i=0;i<nr_keys;i++))
            do

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
                    echo "Warning: X11Forwarding should be 'no'."
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

                if [[ ${arrkeys[$i]} == "PubkeyAuthentication" && ${arrvalues[$i]} != 'yes' ]]
                then 
                    echo "Critical: PubkeyAuthentication must be yes."
                    ok=1
                fi

                if [[ ${arrkeys[$i]} == "LoginGraceTime" && ${arrvalues[$i]} != '1m' ]]
                then 
                    echo "Warning: LoginGraceTime should be 1m."
                    ok=1
                fi

                if [[ ${arrkeys[$i]} == "StrictModes" && ${arrvalues[$i]} != "yes" ]]
                then
                    echo "Critical: StrictModes should be 'yes."
                    ok=1
                fi

                if [[ ${arrkeys[$i]} == "IgnoreRhosts" && ${arrvalues[$i]} != "yes" ]]
                then
                    echo "Warning: IgnoreRhosts should be 'yes'."
                    ok=1
                fi

                if [[ ${arrkeys[$i]} == "HostbasedAuthentication" && ${arrvalues[$i]} != "no" ]]
                then
                    echo "Critical: HostbasedAuthentication must be 'no'."
                    ok=1
                fi

                if [[ ${arrkeys[$i]} == "PermitUserEnvironment" && ${arrvalues[$i]} != "no" ]]
                then
                    echo "Warning: PermitUserEnvironment should be 'no'."
                    ok=1
                fi

                if [[ ${arrkeys[$i]} == "AllowAgentForwarding" && ${arrvalues[$i]} == "yes" ]]
                then
                    echo "Info: AllowAgentForwarding is 'yes'. Ensure this server is trusted."
                fi

                if [[ ${arrkeys[$i]} == "LogLevel" && ${arrvalues[$i]} == "QUIET" ]]
                then
                    echo "Warning: LogLevel should be INFO or VERBOSE, not QUIET."
                    ok=1
                fi

            done

            if (( $ok == 0 ))
            then
                echo "The file doesn't have any errors."
            fi

        else 
            echo "File doesn't have the correct permissions."
            exit 0 
        fi
    fi

else
    echo "SSH Daemon isn't running."
fi

exit 0