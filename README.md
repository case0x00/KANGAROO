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
