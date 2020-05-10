#!/bin/bash
# based on https://github.com/nahamsec/lazyrecon

# pretty colors
red=`tput setaf 1`
yellow=`tput setaf 3`
reset=`tput sgr0`

# configuration
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
    echo "${red}"
    cat << "EOF"
                                    @whichtom
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
    i=1
    n=$(wc -l < ./$domain/subdomains.txt)
    
    echo -ne "\r${red}::${reset} Checking status of listed subdomains:\n"
    while read LINE; do
        echo "$LINE" | httprobe -t 5000 >> ./$domain/responsive.txt
        progressbar ${i} ${n}
        ((i=i+1))
    done < ./$domain/subdomains.txt

    printf "\n${red}::${reset} Done!\n"
    m=$(wc -l < ./$domain/responsive.txt)
    echo -ne "${red}::${reset} Total $n subdomains after check. Reduced by $((n - m))\n"
}

aqua(){
    # aquatone for nice visualization
    echo -ne "${red}::${reset} Starting aquatone...\n"
    cat ./$domain/responsive.txt | aquatone -chrome-path $chromePath -out ./$domain/aqua-out -threads 5 -silent
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
