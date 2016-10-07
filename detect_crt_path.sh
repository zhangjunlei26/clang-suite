
bits=$1

for loc in "/usr/lib/x86_64-linux-gnu" "/usr/lib32" "/usr/lib64" "/usr/lib" ; do

    file "$loc/crt1.o" | grep $bits > /dev/null
    if [ $? -eq 0 ]; then
        echo $loc
        exit 0
    fi
done

exit 1

