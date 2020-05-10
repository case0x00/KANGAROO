#!/bin/bash
# based on https://github.com/nahamsec/lazyrecon

# pretty colors
red=`tput setaf 1`
yellow=`tput setaf 3`
reset=`tput sgr0`

# configuration
chromePath=/usr/bin/google-chrome
identifier=

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


set-scope(){
    # check if scope is unset or is an empty string
    # not working yet
    if [ -z $scope ]; then
        echo -ne "\n${red}::${reset} No scope specified, saving report folder to current working directory\n"
    else
        echo -ne "\n${red}::${reset} Scope set to: $scope\n"
    fi
}

exclusion(){
    # check if the array excluded is empty
    if [ ${#excluded[@]} -eq 0 ]; then
        echo -ne "\n${red}::${reset} No subdomain exclusions to apply\n"
    else
        echo -ne "\n${red}::${reset} Excluding specified subdomains:\n"
        IFS=$'\n'
        printf "%s\n" "${excluded[*]}" > ./$domain/excluded.txt
        grep -vFf ./$domain/excluded.txt ./$domain/subdomains.txt > ./$domain/subdomains2.txt
        mv ./$domain/subdomains2.txt ./$domain/subdomains.txt
        printf "%s\n" "${excluded[@]}"
        unset IFS
    fi
}

recon(){
    # runs sublist3r and file exclusion (if selected)
    printf "${red}::${reset} Listing subdomains using Sublist3r...\n"
    python3 ~/tools/Sublist3r/sublist3r.py -d $domain -v -o ./$domain/subdomains.txt > /dev/null
    printf "\r${red}::${reset} Listing subdomains using Sublist3r... Done!"
    exclusion
    echo -e "\r${red}::${reset} Excluding specified subdomains... Done!"
}

check-ok(){
    # checks for 200, 403, and 500. others arent as interesting most of the time
    i=1
    n=$(wc -l < ./$domain/subdomains.txt)
    
    echo -ne "\r${red}::${reset} Checking status of listed subdomains:\n"
    while read LINE; do
        curl -L --max-redirs 10 -H "X-Bug-Bounty:HackerOne-$identifier" -o /dev/null -m 5 --silent --get --write-out "%{http_code} $LINE\n" "$LINE" >> ./$domain/list.txt
        progressbar ${i} ${n}
        ((i=i+1))
    done < ./$domain/subdomains.txt

    # this could be done way better
    sed '/^200/ !d' < ./$domain/list.txt > ./$domain/domain-status.txt
    sed '/^403/ !d' < ./$domain/list.txt >> ./$domain/domain-status.txt
    sed '/^500/ !d' < ./$domain/list.txt >> ./$domain/domain-status.txt
    cat ./$domain/domain-status.txt | sort -u > ./$domain/responsive.txt
    rm ./$domain/list.txt

    printf "\n${red}::${reset} Done!\n"
    m=$(wc -l < ./$domain/domain-status.txt)
    echo -ne "${red}::${reset} Total $n subdomains after check. Reduced by $((n - m))\n"
    rm ./$domain/domain-status.txt
}

aqua(){
    # aquatone for nice visualization
    echo -ne "${red}::${reset} Starting aquatone...\n"
    sed 's/^....//' < ./$domain/responsive.txt > ./$domain/aqua-resp.txt
    cat ./$domain/aqua-resp.txt | aquatone -chrome-path $chromePath -out ./$domain/aqua-out -threads 5 -silent
    rm ./$domain/aqua-resp.txt
}

progressbar(){
    # nice progress bar
    let progress="(${1}*100/${2}*100)/100"
    let done="(${progress}*6)/10"
    let left=60-$done
    done=$(printf "%${done}s")
    left=$(printf "%${left}s")
    printf "\r${red}::${reset} [${done// /${red}=}>${reset}${left// / }] $1/$2"

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

    if [[ -z $identifier ]]; then
        echo "${red}::${reset} identifier for status checker is blank. Set in the config"
        exit 1
    else
        echo "${red}::${reset} Identifier set as: X-Bug-Bounty:HackerOne-$identifier"
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
