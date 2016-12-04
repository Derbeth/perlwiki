#!/bin/sh
set -e

echo ...util
perl test/util.pl
echo ...addaudio
perl test/addaudio.pl
echo ...cache
perl test/cache.pl
echo ...commons
perl test/commons.pl
echo ...inflection
perl test/inflection.pl
echo ...syntax
./test/syntax.sh
