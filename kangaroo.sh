#!/bin/bash
# based on https://github.com/nahamsec/lazyrecon

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
chromePath=/usr/bin/google-chrome

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
        s)
            scope=${OPTARG} # ikinda need to append '/' to the end so it doesnt fuck up comms if its null
            ;;
    esac
done
shift $((OPTIND - 1))

exclusion(){
	if [ ${#excluded[@]} -eq 0 ]; then
		echo "${red}::${reset} No subdomain exclusions to apply"
	else
		echo -ne "${red}::${reset} Excluding specified subdomains:\n"
		IFS=$'\n'
		printf "%s\n" "${excluded[*]}" > ./$domain/excluded.txt
		grep -vFf ./$domain/excluded.txt ./$domain/subdomains.txt > ./$domain/subdomains2.txt
		mv ./$domain/subdomains2.txt ./$domain/subdomains.txt
		printf "%s\n" "${excluded[@]}"
		unset IFS
	fi
}

recon(){
    echo -ne "${red}::${reset} Listing subdomains using Sublist3r...\n"
    python3 ~/tools/Sublist3r/sublist3r.py -d $domain -v -o ./$domain/subdomains.txt > /dev/null
    echo -e "\r${red}::${reset} Listing subdomains using Sublist3r... Done!"
    exclusion
    echo -e "\r${red}::${reset} Excluding specified subdomains... Done!"
}

check-ok(){
    echo -ne "${red}::${reset} Checking status of listed subdomains...\n"
    i=1
    n=$(wc -l < ./$domain/subdomains.txt)

    while read LINE; do
        curl -L --max-redirs 10 -o /dev/null -m 5 --silent --get --write-out "%{http_code} $LINE\n" "$LINE" >> ./$domain/list.txt
        printf "${red}::${reset} Completed: $i/$n\r"
        ((i=i+1))
    done < ./$domain/subdomains.txt

    sed '/^200/ !d' < ./$domain/list.txt > ./$domain/domain-status.txt
    sed '/^403/ !d' < ./$domain/list.txt >> ./$domain/domain-status.txt
    sed '/^500/ !d' < ./$domain/list.txt >> ./$domain/domain-status.txt
    cat ./$domain/domain-status.txt | sort -u > ./$domain/responsive.txt
    rm ./$domain/list.txt

    echo -ne "${red}::${reset} Checking status of listed subdomains... Done!\n"
    m=$(wc -l < ./$domain/domain-status.txt)
    echo -ne "${red}::${reset} Total $n subdomains after check. Reduced by $((n - m))\n"
    rm ./$domain/domain-status.txt
}

aqua(){
    echo -ne "${red}::${reset} Starting aquatone...\n"
    sed 's/^....//' < ./$domain/responsive.txt > ./$domain/aqua-resp.txt
    cat ./$domain/aqua-resp.txt | aquatone -chrome-path $chromePath -out ./$domain/aqua-out -threads 5 -silent
    rm ./$domain/aqua-resp.txt
}

main(){
    clear
    logo
    echo "${red}@whichtom${reset}"
    echo "${red}::${reset} Hitting target $domain..."
    if [[ -d "./$domain" ]]; then
        echo "${red}::${reset} Target already known, directory already exists"
    else
        mkdir ./$domain
    fi
    
    recon $domain
    check-ok $domain
    aqua $domain
    duration=$SECONDS
    echo "${red}::${reset} Subdomain reconnaissance completed in: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
    stty sane
    tput sgr0
}

main $domain
