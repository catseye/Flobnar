module Main where

import Haste
import Haste.DOM
import Haste.Events

import Flobnar

main = withElems ["prog", "result", "run-button"] driver

escapeHTML "" = ""
escapeHTML ('<' : rest) = "&lt;" ++ escapeHTML rest
escapeHTML ('>' : rest) = "&gt;" ++ escapeHTML rest
escapeHTML ('&' : rest) = "&amp;" ++ escapeHTML rest
escapeHTML (c   : rest) = (c : escapeHTML rest)

driver [progElem, resultElem, runButtonElem] = do
    onEvent runButtonElem Click $ \_ -> execute
    where
        execute = do
            Just prog <- getValue progElem
            setProp resultElem "innerHTML" (escapeHTML $ showRun prog)
