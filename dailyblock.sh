#!/bin/sh

rm -f to_block.txt

./block_from_log.pl -l 350 -r
./block_centrump2p.pl -r
./block_coolproxy.pl -r
./block_ifreeproxies.pl
./block_newipnow.pl -r
./block_proksi.pl -r
./block_proxylist.pl -r
./block_samair.pl -r
./block_projecthoneypot.pl -r
