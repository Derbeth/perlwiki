#!/bin/sh
set -e

echo ...addaudio
./test/addaudio.pl
echo ...cache
./test/cache.pl
echo ...commons
./test/commons.pl
echo ...inflection
./test/inflection.pl
