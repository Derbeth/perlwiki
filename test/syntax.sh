#!/bin/sh

set -e
cd "$(dirname "$0")/.."
perl -c audio_errors.pl
perl -c audio_fetcher.pl
perl -c audiosetter.pl
perl -c count_audio.pl
perl -c dewikt_audiosetter_de.pl
perl -c plnews_month.pl
perl -c sort_commons_cat.pl
