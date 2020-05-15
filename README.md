```

 ___  __    ________  ________   ________  ________  ________  ________  ________     
|\  \|\  \ |\   __  \|\   ___  \|\   ____\|\   __  \|\   __  \|\   __  \|\   __  \    
\ \  \/  /|\ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \   
 \ \   ___  \ \   __  \ \  \\ \  \ \  \  __\ \   __  \ \   _  _\ \  \\\  \ \  \\\  \  
  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \|\  \ \  \ \  \ \  \\  \\ \  \\\  \ \  \\\  \ 
   \ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \__\ \__\ \__\\ _\\ \_______\ \_______\
    \|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|__|\|__|\|__|\|__|\|_______|\|_______|
                                                                                      
                                                                                      
```

# Kangaroo

Lightweight recon script that uses sublist3r to search for subdomains with httprobe checking for status, performing aquatone for visualization. Makes a new directory with the domain name in the current working directory.

Inspired by lazyrecon since that is a little too traffic heavy for me.

# Usage
`./kangaroo.sh -d domain.com [-e] [sub.domain.com, ...]`

# To do
* add more search tools to grab more subdomains
* dirsearch
* CNAME records?
* scope assignment (e.g. scope to verizonmedia would put all subdomains into a verizonmedia directory, '[-s] [scope]')
* verbosity flag for sublist3r
* checkpoints to pause and resume check-ok? how tf would that work? It would have to check if a checkpoint file exists, if t then read file and grab index, start httprobe at subdomains.txt[i]. Alternatively, check if chkpt exists, if t then apply exclusion to every subdomain in the existing responsive.txt? only 25% efficient with that method.
