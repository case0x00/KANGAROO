#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SECONDS=0

logo(){
    echo "${yellow}"
    cat << "EOF"
 ___  __    ________  ________   ________  ________  ________  ________  ________
|\  \|\  \ |\   __  \|\   ___  \|\   ____\|\   __  \|\   __  \|\   __  \|\   __  \
\ \  \/  /|\ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \
 \ \   ___  \ \   __  \ \  \\ \  \ \  \  __\ \   __  \ \   _  _\ \  \\\  \ \  \\\  \
  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \|\  \ \  \ \  \ \  \\  \\ \  \\\  \ \  \\\  \
   \ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \__\ \__\ \__\\ _\\ \_______\ \_______\
    \|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|__|\|__|\|__|\|__|\|_______|\|_______|

EOF
echo "${reset}"
}

recon(){
    echo -ne "Listing subdomains using Sublist3r...\n"
    python3 ~/tools/Sublist3r/sublist3r.py -d $1 -v -o ./$1/subdomains2.txt > /dev/null
    echo -e "\rListing subdomains using Sublist3r... Done!"

}

exclusion(){
    echo "Excluding domains..."
    printf "%s\n" "${exluded[*]}" > ./$1/excluded.txt
    grep -vFf ./$1/subdomains2.txt ./$1/excluded.txt > ./$1/subdomains.txt
    rm ./$1/subdomains2.txt
}

check-ok(){
    echo -ne "Checking status of listed subdomains...\n"
    i=1
    n=$(wc -l < ./$1/subdomains.txt)

    while read LINE; do
        curl -L --max-redirs 10 -o /dev/null -m 5 --silent --get --write-out "%{http_code} $LINE\n" "$LINE" >> list.txt
        printf "Completed: $i/$n\r"
        ((i=i+1))
    done < ./$1/subdomains.txt

    sed '/^200/ !d' < list.txt > ./$1/domain-status.txt
    rm list.txt
    echo "Checking status of listed subdomains... Done!"
}

main(){
    clear
    logo
    echo "@whichtom"
    if [[ -d "./$1" ]]; then
        echo "Target already known"
    else
        mkdir ./$1
    fi
    
    recon $1
    check-ok $1
    duration=$SECONDS
    echo "Subdomain reconnaissance completed in: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
    stty sane
    tput sgr0
}

main $1
