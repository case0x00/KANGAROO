#!/bin/bash
# based on https://github.com/nahamsec/lazyrecon

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SECONDS=0

domain=
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

while getopts ":d:e:" o; do
    case "${o}" in
        d)
            domain=${OPTARG}
            ;;

         e)
            set -f
            IFS=","
            excluded+=($OPTARG)
            unset IFS
            ;;
    esac
done
shift $((OPTIND - 1))

exclusion(){
    IFS=$'\n'
    printf "%s\n" "${excluded[*]}" > ./$domain/excluded.txt
    grep -vFf ./$domain/excluded.txt ./$domain/subdomains.txt > ./$domain/subdomains2.txt
    mv ./$domain/subdomains2.txt ./$domain/subdomains.txt
    printf "%s\n" "${excluded[@]}"
    unset IFS
}

recon(){
    echo -ne "Listing subdomains using Sublist3r...\n"
    python3 ~/tools/Sublist3r/sublist3r.py -d $domain -v -o ./$domain/subdomains.txt > /dev/null
    echo -e "\rListing subdomains using Sublist3r... Done!"
    echo -ne "Excluding specified domains:\n"
    exclusion
    echo -e "\rExcluding specified domains... Done!"
}

check-ok(){
    echo -ne "Checking status of listed subdomains...\n"
    i=1
    n=$(wc -l < ./$domain/subdomains.txt)

    while read LINE; do
        curl -L --max-redirs 10 -o /dev/null -m 5 --silent --get --write-out "%{http_code} $LINE\n" "$LINE" >> ./$domain/list.txt
        printf "Completed: $i/$n\r"
        ((i=i+1))
    done < ./$domain/subdomains.txt

    sed '/^200/ !d' < ./$domain/list.txt > ./$domain/domain-status.txt
    rm ./$domain/list.txt

    echo -ne "Checking status of listed subdomains... Done!\n"
    m=$(wc -l < ./$domain/domain-status.txt)
    echo -ne "Total $n subdomains after check. Reduced by $((n - m))\n"
}

main(){
    clear
    logo
    echo "@whichtom"
    echo "Hitting target $domain..."
    if [[ -d "./$domain" ]]; then
        echo "Target already known, directory already exists"
    else
        mkdir ./$domain
    fi
    
    recon $domain
    check-ok $domain
    duration=$SECONDS
    echo "Subdomain reconnaissance completed in: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
    stty sane
    tput sgr0
}

main $domain
