#!/bin/sh

rsync -avz -e "ssh" --progress --backup --update --delete derbeth@tools.wikimedia.pl:~/src/perlwiki/done/*.txt done
