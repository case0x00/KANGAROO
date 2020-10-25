#!/bin/bash
# based on https://github.com/nahamsec/lazyrecon

# pretty colors
RED=$(printf '\033[31m')
BLUE=$(printf '\033[34m')
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[m')

# configuration
chromePath=/usr/bin/google-chrome
sublist3rPath=/opt/Sublist3r

SECONDS=0

doaqua=
domain=

while getopts ":d:s:e" flag; do
    case "${flag}" in
        d)
            domain=${OPTARG}
            ;;
        s)
            screenshot=${OPTARG}
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


logo(){
    echo "${YELLOW}"
    cat << "EOF"
 ___  __    ________  ________   ________  ________  ________  ________  ________
|\  \|\  \ |\   __  \|\   ___  \|\   ____\|\   __  \|\   __  \|\   __  \|\   __  \
\ \  \/  /|\ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \
 \ \   ___  \ \   __  \ \  \\ \  \ \  \  __\ \   __  \ \   _  _\ \  \\\  \ \  \\\  \
  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \|\  \ \  \ \  \ \  \\  \\ \  \\\  \ \  \\\  \
   \ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \__\ \__\ \__\\ _\\ \_______\ \_______\
    \|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|__|\|__|\|__|\|__|\|_______|\|_______|

EOF
echo "${RESET}"
}

# to do: scope
#set-scope(){
#    # check if scope is unset or is an empty string
#    if [ -z $scope ]; then
#        echo -ne "\n${RED}::${RESET} No scope specified, saving report folder to current working directory\n"
#    else
#        echo -ne "\n${RED}::${RESET} Scope set to: $scope\n"
#    fi
#}

exclusion(){
    # excludes subdomains from check-ok
    if [ ${#excluded[@]} -eq 0 ]; then
        echo -ne "\n${RED}::${RESET} No subdomain exclusions to apply\n"
    else
        echo -ne "\n${RED}::${RESET} Excluding specified subdomains:\n"
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
    printf "${RED}::${RESET} Listing subdomains using Sublist3r...\n"
    python3 $sublist3rPath/sublist3r.py -d $domain -v -o ./$domain/subdomains.txt #> /dev/null
    printf "\r${RED}::${RESET} Done!\n"
    printf "${RED}::${RESET} $(wc -l < ./$domain/subdomains.txt) subdomains listed."
    exclusion
}

check-ok(){
    # uses httprobe to check whether the subdomain is alive
    i=1
    n=$(wc -l < ./$domain/subdomains.txt)
    
    echo -ne "\r${RED}::${RESET} Checking status of listed subdomains..."
    cat ./$domain/subdomains.txt | httprobe -t 3000 >> ./$domain/responsive-tmp.txt
    cat ./$domain/responsive-tmp.txt | sed 's/\http\:\/\///g' | sed 's/\https\:\/\///g' | sort -u >> ./$domain/responsive.txt
    rm ./$domain/responsive-tmp.txt

    printf "\n${RED}::${RESET} Done!\n"
    m=$(wc -l < ./$domain/responsive.txt)
    echo -ne "${RED}::${RESET} Total $m subdomains after check. Reduced by $((n - m)).\n"
}

aqua(){
    # aquatone for nice visualization
    cat ./$domain/responsive.txt | aquatone -chrome-path $chromePath -out ./$domain/aqua-out -threads 5 -silent
}

eyew(){
    # https://tools.kali.org/information-gathering/eyewitness
    # must be run as root
    eyewitness -f $1 --headless -d ./$domain --no-prompt --threads 5
}


progress-bar(){
    # nice progress bar
    let progress="(${1}*100/${2}*100)/100"
    let done="(${progress}*6)/10"
    let left=60-$done
    done=$(printf "%${done}s")
    left=$(printf "%${left}s")
    printf "\r${RED}::${RESET} [${done// /${RED}=}>${RESET}${left// / }] $1/$2"

}

check-time(){
    taskname=$1
    duration=$SECONDS
    echo "${RED}::${RESET} $taskname completed after: $(($duration/ 60)) minutes and $(($duration% 60)) seconds."
}

main(){
    clear
    logo
    echo "${RED}built with <3 by case${RESET}"

    echo "${RED}::${RESET} Hitting target $domain..."
    if [[ -d "./$domain" ]]; then
        echo "${RED}::${RESET} Target already known, directory already exists."
    else
        mkdir ./$domain
    fi

    recon $domain
    check-time "Sublist3r"

    check-ok $domain
    check-time "Httprobe"

    if [[ $screenshot == "eyewitness" ]]; then
        echo -ne "${RED}::${RESET} Starting EyeWitness...\n"
        eyew ./$domain/responsive.txt $domain
        check-time "EyeWitness"

    elif [[ $screenshot == "aquatone" ]]; then
        echo -ne "${RED}::${RESET} Starting aquatone...\n"
        aqua $domain
        check-time "Aquatone"
    else
        echo -ne "${RED}::${RESET} Screenshot tool not specified.\n"
    fi

    check-time "Total subdomain reconnaissance"
    stty sane
    tput sgr0
}
main $domain 
