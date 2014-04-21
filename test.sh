#!/bin/sh

if [ x`which ghc` = x -a x`which runhugs` = x ]; then
    echo "Neither ghc nor runhugs found on search path"
    exit 1
fi

touch fixture.markdown

if [ ! x`which ghc` = x ]; then
    cat >>fixture.markdown <<EOF
    -> Functionality "Interpret Flobnar program" is implemented by
    -> shell command
    -> "ghc src/Flobnar.hs -e "do c <- readFile \"%(test-body-file)\"; putStr $ showRun c""

EOF
fi

if [ ! x`which runhugs` = x ]; then
    cat >>fixture.markdown <<EOF
    -> Functionality "Interpret Flobnar program" is implemented by
    -> shell command
    -> "runhugs src/Main.hs %(test-body-file)"

EOF
fi

falderal -b fixture.markdown README.markdown
rm -f fixture.markdown
