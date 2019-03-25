-- encoding: UTF-8

--
-- Copyright (c)2011 Chris Pressey, Cat's Eye Technologies.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
--   1. Redistributions of source code must retain the above copyright
--      notices, this list of conditions and the following disclaimer.
--   2. Redistributions in binary form must reproduce the above copyright
--      notices, this list of conditions, and the following disclaimer in
--      the documentation and/or other materials provided with the
--      distribution.
--   3. Neither the names of the copyright holders nor the names of their
--      contributors may be used to endorse or promote products derived
--      from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
-- FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
-- COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
-- BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
-- ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--

module Flobnar where

import qualified Data.Map as Map
import qualified Data.Char as Char

data Value = IntVal Integer
             deriving (Show, Ord, Eq)

-- ======================================= --
-- Playfield data definition and functions --
-- ======================================= --

type Playfield = Map.Map (Integer,Integer) Integer

emptyPlayfield :: Playfield
emptyPlayfield = Map.empty

get :: Playfield -> Integer -> Integer -> Integer
get pf x y = Map.findWithDefault 32 (x, y) pf

put :: Playfield -> Integer -> Integer -> Integer -> Playfield
put pf x y value =
    case value of
        32 -> Map.delete (x, y) pf
        _ -> Map.insert (x, y) value pf

putc :: Playfield -> Integer -> Integer -> Char -> Playfield
putc pf x y char = put pf x y (toInteger $ Char.ord char)

loadLine pf x y [] = pf
loadLine pf x y (char:chars) =
    loadLine (putc pf x y char) (x+1) y chars

loadLines pf x y [] = pf
loadLines pf x y (line:lines) =
    loadLines (loadLine pf x y line) x (y+1) lines

load lines = loadLines emptyPlayfield 0 0 lines

locate pf value =
    let
        f accum key val =
            if val == value then
                ((key:accum), val)
            else
                (accum, val)
    in
        fst $ Map.mapAccumWithKey f [] pf

extents pf =
    let
        f (lowX, lowY, highX, highY) (x, y) val =
            let
                lowX' = if x < lowX then x else lowX
                lowY' = if y < lowY then y else lowY
                highX' = if x > highX then x else highX
                highY' = if y > highY then y else highY
            in
                ((lowX', lowY', highX', highY'), val)
    in
        fst $ Map.mapAccumWithKey f (1000, 1000, (-1000), (-1000)) pf

-- ================== --
-- Flobnar evaluation --
-- ================== --

--
-- Evaluation is implemented as a set of mutually recursive functions.
-- Evaluation functions return a pair of (result value, new playfield).
-- All terms except p leave the playfield unchanged.
--
-- env is a list of values; each value is the argument that was passed
-- to a function that was called to get here.
--
-- dx and dy are the delta that the expression is being evaluated from:
--
-- dx=0, dy=1: being evaluated from the north (toward the south)
-- dx=0, dy=-1: being evaluated from the south (toward the north)
-- dx=1, dy=0: being evaluated from the west (toward the east)
-- dx=-1, dy=0: being evaluated from the east (toward the west)
--
-- Terms should call one of these 6 functions to evaluate another
-- location in the playfield, as these functions handle wrapping.
-- Don't call eval directly unless you know (x, y) is in the playfield.
--

evalEast env pf x y = evalDelta env pf 1 0 x y
evalWest env pf x y = evalDelta env pf (-1) 0 x y
evalNorth env pf x y = evalDelta env pf 0 (-1) x y
evalSouth env pf x y = evalDelta env pf 0 1 x y
evalDelta env pf dx dy x y = evalLeap env pf dx dy dx dy x y
evalLeap env pf dx dy leapDx leapDy x y =
    let
        (nx, ny) = wrap pf (x+leapDx) (y+leapDy)
    in
        eval env pf dx dy nx ny

wrap pf x y =
    let
        (lowX, lowY, highX, highY) = extents pf
        x' = if (x < lowX) then highX-(lowX-x)+1 else
               if (x > highX) then lowX+(x-highX)-1 else x
        y' = if (y < lowY) then highY-(lowY-y)+1 else
               if (y > highY) then lowY+(y-highY)-1 else y
    in
        (x', y')


eval env pf dx dy x y =
    let
        term = Char.chr $ fromInteger $ get pf x y
    in
        evalThe term env pf dx dy x y

--
-- Evaluation of individual terms.  The meaning of each of these is
-- explained in the documentation.
--

evalThe :: Char -> [Value] -> Playfield -> Integer -> Integer -> Integer -> Integer -> (Value, Playfield)

evalThe ':' (arg:env) pf dx dy x y = (arg, pf)
evalThe ':' [] pf dx dy x y = (IntVal 0, pf)

evalThe '$' (arg:env) pf dx dy x y = evalDelta env pf dx dy x y
evalThe '$' [] pf dx dy x y = evalDelta [] pf dx dy x y

evalThe '\\' env pf dx dy x y =
    let
        (arg, pf') = evalSouth env pf x y
    in
        evalDelta (arg:env) pf' dx dy x y

evalThe '>' env pf dx dy x y = evalEast env pf x y
evalThe '<' env pf dx dy x y = evalWest env pf x y
evalThe 'v' env pf dx dy x y = evalSouth env pf x y
evalThe '^' env pf dx dy x y = evalNorth env pf x y

evalThe '_' env pf dx dy x y =
    case evalDelta env pf dx dy x y of
        (IntVal 0, pf') -> evalEast env pf' x y
        (_, pf') ->        evalWest env pf' x y

evalThe '|' env pf dx dy x y =
    case evalDelta env pf dx dy x y of
        (IntVal 0, pf') -> evalSouth env pf' x y
        (_, pf') ->        evalNorth env pf' x y

evalThe '@' env pf dx dy x y = evalWest env pf x y

evalThe '!' env pf dx dy x y =
    case evalDelta env pf dx dy x y of
        (IntVal 0, pf') -> (IntVal 1, pf')
        (_, pf')        -> (IntVal 0, pf')

evalThe ' ' env pf dx dy x y =
    evalDelta env pf dx dy x y

evalThe '#' env pf dx dy x y =
    evalLeap env pf dx dy (dx*2) (dy*2) x y

evalThe digit env pf dx dy x y
    | Char.isDigit digit = (IntVal $ toInteger $ Char.digitToInt digit, pf)

evalThe oper env pf dx dy x y =
    let
        (IntVal north, pf')  = evalNorth env pf x y
        (IntVal south, pf'') = evalSouth env pf' x y
    in
        case oper of
            '+' -> (IntVal (north + south), pf'')
            '*' -> (IntVal (north * south), pf'')
            '-' -> (IntVal (north - south), pf'')
            '/' -> case south of
                      0 -> evalDelta env pf'' dx dy x y
                      _ -> (IntVal (north `div` south), pf'')
            '%' -> case south of
                      0 -> evalDelta env pf'' dx dy x y
                      _ -> (IntVal (north `rem` south), pf'')
            '`' -> case north > south of
                      True -> (IntVal 1, pf'')
                      False -> (IntVal 0, pf'')
            'g' -> (IntVal $ get pf'' north south, pf'')
            'p' -> let
                       (IntVal value, pf''') = evalDelta env pf'' dx dy x y
                       pf'''' = put pf''' north south value
                   in
                       (IntVal 0, pf'''')
            _ ->
                error "undefined term"

--
-- Main entry points for executing Flobnar programs.
--

run program =
    let
        pf = load (lines program)
    in
        case locate pf $ toInteger $ Char.ord '@' of
            [(x, y)] ->
                let
                    (result, pf') = eval [] pf 0 0 x y
                in
                    result
            _ ->
                error "Program does not contain exactly one @"

showRun program =
    case run program of
        IntVal x -> "Result: " ++ (show x) ++ "\n"
