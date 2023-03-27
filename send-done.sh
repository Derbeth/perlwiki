#!/bin/sh

rsync -avz -e "ssh" --progress --backup --update --delete --filter '. rsync.cfg' . $PERLWIKI_SYNC_HOST:~/devel/perlwiki/
