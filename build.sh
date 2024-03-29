#!/bin/sh

PROG=flobnar

if command -v ghc >/dev/null 2>&1; then
    echo "building $PROG.exe with ghc"
    (cd src && ghc --make Main.hs -o ../bin/$PROG.exe)
else
    echo "ghc not found, not building $PROG.exe"
fi

if command -v hastec >/dev/null 2>&1; then
    echo "building $PROG.js with hastec"
    (cd src && hastec --make HasteMain.hs -o $PROG.js && mv $PROG.js ../demo/$PROG.js)
else
    echo "hastec not found, not building $PROG.js"
fi
