#!/bin/sh
set -e

echo ...addaudio
perl test/addaudio.pl
echo ...cache
perl test/cache.pl
echo ...commons
perl test/commons.pl
echo ...inflection
perl test/inflection.pl
