GPLV3.0 or later copyright brmlab.cz contact timothyhobbs@seznam.cz

Also copyright cheater http://cheater.posterous.com/haskell-curses

Copyright 2012.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

>module Main where

>import Util.ConfigSelect
>import System.Environment

>main :: IO ()
>main = do
> args <- getArgs
> case args of
>  [destDir,profilesDir,profile] -> loadProfile destDir profilesDir profile
>  [destDir,profilesDir] -> profileSellector destDir profilesDir
>  _ -> putStrLn explanationOfConfigSelector
