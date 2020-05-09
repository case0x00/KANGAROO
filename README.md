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

Super lightweight recon script that just uses sublist3r to search for subdomains, then sorts only looking for 200, 403, and 500 following 301 redirects with a 5 second max timeout for any operation. Makes a new directory with the domain's name in the current working directory.

Inspired by lazyrecon since that is a little too traffic heavy for me.

# Usage
`./kangaroo.sh -d domain.com [-e] [sub.domain.com, ...]`

# To do
* add more search tools to grab more subdomains passively and sort unique
* CNAME records?
* scope assignment (e.g. scope to verizonmedia would put all subdomains into a verizonmedia directory, '[-s] [scope]')
