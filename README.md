```

 ___  __    ________  ________   ________  ________  ________  ________  ________     
|\  \|\  \ |\   __  \|\   ___  \|\   ____\|\   __  \|\   __  \|\   __  \|\   __  \    
\ \  \/  /|\ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \   
 \ \   ___  \ \   __  \ \  \\ \  \ \  \  __\ \   __  \ \   _  _\ \  \\\  \ \  \\\  \  
  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \|\  \ \  \ \  \ \  \\  \\ \  \\\  \ \  \\\  \ 
   \ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \__\ \__\ \__\\ _\\ \_______\ \_______\
    \|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|__|\|__|\|__|\|__|\|_______|\|_______|
                                                                                      
                                                                                      
```

# kangaroo

its my lightweight subdomain recon script. it uses sublist3r to search for subdomains then uses two layers of filtering: httprobe checks status, then aquatone/eyewitness screenshots (and checks status again). in the process it makes a new directory with the domain name in the current working directory.

inspired by lazyrecon since that is a little too traffic heavy for me.

# Usage
`./kangaroo.sh -d domain.com [-s] [aquatone/eyewitness] [-e] [sub.domain.com, ...]`

# To do
* add more search tools to grab more subdomains
* CNAME records?
* verbosity flag for sublist3r
* i would like a progress bar for httprobe but idk if thats possible
