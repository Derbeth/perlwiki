#!/bin/sh

rsync -avz -e "ssh" --progress --backup --update --delete $PERLWIKI_SYNC_HOST:~/devel/perlwiki/done/*.txt done
