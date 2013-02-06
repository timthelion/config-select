How to use ghc-vis when your libraries are all compiled with profiling...
========

I always keep:

    executable-profiling: True
    library-profiling: True

in my `~/.cabal/config`.  Profiling is useful, and its a pain when you cannot use it.

But ghc-vis doesn't work with profiling.
That's a bummer.
Should I recompile the universe every time I want to use ghc-vis?
Should I use cabal-dev and move things back and forth?

No!

There's a better way(tm).
That is config-select

config-select is a program which is generally usefull for swapping out config files.

It can be installed with the command:
`cabal install config-select`

It was origionally developed as an X11 display manager to swap out .xinitrc files.

It provides you with a nice menu to select the configuration profile you want.
Or you can pass a profile's name via the command line to load it instantly.

The fundimental files directories of config-select are as follows:

A profiles directory:

`~/.xinitrc.d/`

A profile directory:

`~/.xinitrc.d/xmonad/`

A config file:

`~/.xinitrc.d/xomand/.xinitrc`

Or two:

`~/.xinitrc.d/xmonad/.xmodmap`

Symlinks to the config files.

    lrwxrwxrwx 1 timothy timothy 40  6. úno 21.49 .xinitrc -> .xinitrc.d/xmonad/.xinitrc
    lrwxrwxrwx 1 timothy timothy 40  6. úno 21.49 .xmodmap -> .xinitrc.d/xmonad/.xmodmap

config-select can be now run by the command:

`config-select $HOME $HOME/.xinitrc.d/`

I have a script in my `~/bin` directory named csdm:

    #!/bin/bash
    config-select $HOME $HOME/configs/xinitrc.d/ $1
    exec startx

and I can either run

`$ csdm `

to see a menu and choose between `xfce` and `xmonad` or I can run

`$ csdm xmonad` to launch xmonad directly.

Dealing with the ghc problem is quite similar.  Here is my `~/bin/csghc`:

    #!/bin/bash
    config-select $HOME $HOME/configs/ghc.d/ $1

I then have a ghc.d directory with two subdirectories:

    [timothy@timothy ghc.d]$ ls -la noprofiling-default/
    celkem 4
    drwxr-xr-x 1 timothy timothy  30  6. úno 22.51 .
    drwxr-xr-x 1 timothy timothy  56  6. úno 22.52 ..
    drwxr-xr-x 1 timothy timothy  68  6. úno 22.27 .cabal
    drwxr-xr-x 1 timothy timothy  60  6. úno 22.24 .ghc
    -rw-r--r-- 1 timothy timothy 114  6. úno 22.27 .ghci

    [timothy@timothy ghc.d]$ ls -la profiling/
    celkem 8
    drwxr-xr-x 1 timothy timothy   56  6. úno 22.57 .
    drwxr-xr-x 1 timothy timothy   56  6. úno 22.52 ..
    drwxr-xr-x 1 timothy timothy   68  6. úno 22.15 .cabal
    -rw-r--r-- 1 timothy timothy 2159  9. zář 19.42 .cabal-config
    drwxr-xr-x 1 timothy timothy   96 11. říj 11.39 .ghc
    -rw-r--r-- 1 timothy timothy    1  6. úno 22.57 .ghci

There are several complications:
The first is that the files in the two directories should be the same.
config-select swaps out only files that it finds within the selected profile.

That means, that even though with profiling turned on, I have no need for a `~/.ghci` file, it is blank:

`[timothy@timothy ghc.d]$ cat profiling/.ghci

[timothy@timothy ghc.d]$ cat noprofiling-default/.ghci
:script /home/timothy/.cabal/share/ghc-heap-view-0.4.2.0/ghci
:script /home/timothy/.cabal/share/ghc-vis-0.6/ghci`

I still need a place holder there, so that the `~/.ghci` file installed when noprofiling-default is activated will get replaced by something reasonable when I'm using the profile with profiling enabled.

The seccond complication is more benign.
One must have `~/.cabal/bin` in ones `$PATH`.

But if we are to swap out our `~/.cabal` directory this can lead to otherwise usefull and installed exicutables dissapearing from the path.

My solution is to have a `~/.bashrc` that looks like this:

`PATH=$PATH:$HOME/.cabal/bin:$HOME/configs/ghc.d/profiling/.cabal/bin:$HOME/bin/`

This says that bash should first look for programs installed in `~/.cabal/bin` and when it doesn't find them, it can then continue searching in `~/configs/ghc.d/profiling/.cabal/`.

I hope you enjoyed this tutorial,
and I look forward to any feedback and sugestions.

I have been careful to make config-select not delete everything on your computer.  However, please note that it is still in the testing phase.  Use at your own risk.

Tim
