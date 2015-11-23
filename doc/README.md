# PPOPC Project - Ant ...

## Build

Build the presentation with the makefile

    make
    
## Installation

You will need pandoc to do that, plus tex and the slides.

To acquire the required software under Ubuntu:

    sudo apt-get install pandoc
    sudo apt-get install texlive-full 

To acquire the required software under ArchLinux:

    sudo yaourt -S pandoc-bin
    sudo yaourt -S texlive-most

## Compose several markdown files

To organize the order of included files, simply edit report.md and add the filename where you want it
