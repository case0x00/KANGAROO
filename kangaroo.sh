#!/bin/bash
# based on https://github.com/nahamsec/lazyrecon

# pretty colors
red=`tput setaf 1`
yellow=`tput setaf 3`
reset=`tput sgr0`

# configuration
chromePath=/usr/bin/google-chrome

SECONDS=0

doaqua=
domain=

while getopts ":d:e:a" flag; do
    case "${flag}" in
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
        a)
            doaqua="true"
            ;;
    esac
done
shift $((OPTIND - 1))

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
    # excludes subdomains from check-ok
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
    # uses httprobe to check whether the subdomain is alive
    i=1
    n=$(wc -l < ./$domain/subdomains.txt)
    
    echo -ne "\r${red}::${reset} Checking status of listed subdomains:\n"
    while read LINE; do
        echo "$LINE" | httprobe -t 3000 >> ./$domain/responsive.txt
        progress-bar ${i} ${n}
        ((i=i+1))
    done < ./$domain/subdomains.txt

    printf "\n${red}::${reset} Done!\n"
    m=$(wc -l < ./$domain/responsive.txt)
    echo -ne "${red}::${reset} Total $m subdomains after check. Reduced by $((n - m))\n"
}

aqua(){
    # aquatone for nice visualization
    cat ./$domain/responsive.txt | aquatone -chrome-path $chromePath -out ./$domain/aqua-out -threads 5 -silent
}

progress-bar(){
    # nice progress bar
    let progress="(${1}*100/${2}*100)/100"
    let done="(${progress}*6)/10"
    let left=60-$done
    done=$(printf "%${done}s")
    left=$(printf "%${left}s")
    printf "\r${red}::${reset} [${done// /${red}=}>${reset}${left// / }] $1/$2"

}

check-time(){
    taskname=$1
    duration=$SECONDS
    echo "${red}::${reset} $taskname completed in: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
}

main(){
#    clear
    logo
    echo "${red}@whichtom${reset}"

    echo "${red}::${reset} Hitting target $domain..."
    if [[ -d "./$domain" ]]; then
        echo "${red}::${reset} Target already known, directory already exists"
    else
        mkdir ./$domain
    fi

#    recon $domain
#	check-time "Sublist3r"

#    check-ok $domain
#	check-time "Httprobe"

    if [[ $doaqua == "true" ]]; then
        echo -ne "${red}::${reset} Starting aquatone...\n"
        aqua $domain
        check-time "Aquatone"
    else
        echo -ne "${red}::${reset} Aquatone not being used\n"
    fi

    check-time "Total subdomain reconnaissance"
    stty sane
    tput sgr0
}

main $domain
