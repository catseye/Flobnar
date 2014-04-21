module Main where

import System.Environment
import Flobnar

main = do
    [fileName] <- getArgs
    c <- readFile fileName
    putStr $ showRun c
