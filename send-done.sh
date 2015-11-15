#!/bin/sh

rsync -avz -e "ssh" --progress --backup --update --delete done/*.txt derbeth@tools.wikimedia.pl:~/src/perlwiki/done
rsync -avz -e "ssh" --progress --backup --update --delete audio/*.txt derbeth@tools.wikimedia.pl:~/src/perlwiki/audio
