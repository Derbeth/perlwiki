Perl-based tools for Wikipedia, Wiktionary etc.
===============================================

Overview
--------

*   audio_errors.pl

    prints out a list pronunciation files to be added manually, because audiosetter.pl was unable to add them automatically

*   audio_fetcher.pl

    scans for pronunciation files in Wikimedia Commons and writes results in audio/ directory for later use in scripts setting pronunciation on Wiktionary

*   audiosetter.pl

    reads pronunciation files from audio/ directory and sets them in Wiktionary

*   `commons_sort_fixer.pl`

    sets category sorting of media files on Wikimedia Commons

*   count_audio.pl

    counts how many audio files have been added by audiosetter.pl

*   `dewikt_audiosetter_de.pl`

    adds German pronunciation on German Wiktionary using an improved algorithm


Prerequisites
-------------

Software:

* Unix-like operating system
* Perl
* Perl module MediaWiki::Bot version 3.3.1 or newer

Other:

* account in MediaWiki with bot flag

Copy settings.ini.example to settings.ini and set your bot username and password.


Supported wikis
---------------

audiosetter.pl supports the following Wiktionaries:

* de
* en
* pl
* simple


Usage scenarios
---------------

### Adding audio files to Wiktionary

    ./audio_fetcher.pl
    ./audiosetter.pl -w en -a
    ./count_audio.pl -w en

Short description:

*   ./audio_fetcher.pl

    Saves information on available pronunciation files to audio/ directory.

*   ./audiosetter.pl -w en -a

    Adds pronunciation files on English Wiktionary (`-w en`) in all available languages (`-a`). Will take *a lot of time*, see below how to stop it.

*   ./count_audio.pl -w en

    Prints a MediaWiki table with a summary of work done.

*   ./count_audio.pl -w en > /tmp/en.txt && ./audio_errors.pl -w en >> /tmp/en.txt

    Saves a summary of added files and skipped files to /tmp/en.txt.

You can kill audiosetter.pl at any time using Ctrl+C. It will save progress in done/ directory and resume without repeating anything when started for the next time.

### Running for chosen languages

Use ./audiosetter.pl with option like `-l de,fi,ru` instead of `-a`.

### Running again after all work is done

1.  ./audio_fetcher.pl --cleanstart --cleancache

    audio_fetcher.pl caches web pages, so running it again normally won't detect any new files. Use --cleanstart and --cleancache options to fetch new audio files.

2.  ./audiosetter.pl --cleanstart -w en -a

    After you run audio_fetcher.pl, run audiosetter.pl for the first time with --cleanstart option. This will reset done/ directory and the count of added files. Otherwise audiosetter.pl will consider all work done and finish without doing anything.


Development
-----------

*   test/

    Test harness.


Source code, bug reports
------------------------

[GitHub](https://github.com/Derbeth/perlwiki)


Copyright
---------

All code created by Derbeth under MIT license.

