GPLV3.0 or later copyright Timothy Hobbs contact timothyhobbs@seznam.cz

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

>module Util.ConfigSelect
> (explanationOfConfigSelector
> ,profileSellector
> ,loadProfile) where

>import System.Directory
>import System.FilePath.Posix
>import System.Posix.Files
>import System.IO
>import Graphics.Vty.Menu
>import Data.Foldable hiding(mapM_)
>import Data.Char

>explanationOfConfigSelector = unlines $
> ["config-select allows you to swap out config files."
> ,"The basic philosophy, is to keep a folder, for example ~/.xinitrc.d"
> ,"In which a number of folders containing configuration profiles are held."
> ,"You might have a folder named xmonad, which contains an .xinitrc file for launching xmonad, and another folder named xfce, which contains an .xinitrc file for launching xfce."
> ,"config-select will then be able to make ~/.xinitrc into a symlink to either ~/.xinitrc.d/xmonad/.xinitrc or ~/.xinitrc.d/xfce/.xinitrc"
> ,"This allows you to quickly switch between two configurations of the same program."
> ,""
> ,"USAGE:"
> ,""
> ,"config-select [configuration-home] [profiles-dir] [selection(optional)]"
> ,""
> ,"In the case of our swappable .xinitrc file we could run:"
> ,""
> ,"config-select ~/ ~/.xinitrc.d/"
> ,""
> ,"This would display a menu from which you could select either"
> ,"xmonad or xfce."
> ,""
> ,"Or you could run:"
> ,""
> ,"config-select ~/ ~/.xinitrc.d xmonad"
> ,""
> ,"This would create a symlink from ~/.xinitrc to ~/.xinitrc.d/xomonad/.xinitrc"
> ,"directly without showing any menu."
> ,""
> ,"Configuration profile directories can happilly contain multiple configuration files to be swapped out."]

>profileSellector :: FilePath -> FilePath -> IO ()
>profileSellector destDir profilesDir = checkExistance
> where

Check if the configuration profiles dir exists

> checkExistance = do
>  exists <- doesDirectoryExist profilesDir
>  case exists of
>    True -> loadContents

If it does not exist,
show an error and exit.

>    False ->
>     putStrLn $ "The profiles directory "++profilesDir++" does not exist.\n" ++ explanationOfConfigSelector

load the list of profiles for the user to sellect.
If the user sellects a profile load the profile.
If the user does not sellect a profile,
tell the user that no config was selected and exit.

> loadContents = do
>   profiles' <- getDirectoryContents profilesDir
>   let
>    profiles = directoryContents profiles'
>   profileMaybe <- displayMenu profiles
>   case profileMaybe of
>    Just profile -> loadProfile destDir profilesDir profile
>    Nothing -> do
>     putStrLn "No configuration profile selected. Exiting."

>data ConfigsInDestDir
> = ConfigsInDestDir
>    {activatedWithValidSymlink :: [String]
>    ,presentAsFile             :: [String]
>    ,nonActivated              :: [String]}

>emptyConfigs = ConfigsInDestDir [] [] []

>categorizeConfig
> :: FilePath
> -> FilePath
> -> String
> -> ConfigsInDestDir
> -> IO ConfigsInDestDir
>categorizeConfig
> destDir
> profilesDir
> config
> categorizedConfigs
> = existsCheck
> where
> configDestinationPath = combine destDir config
> existsCheck = do
>  existsAsFile <- doesFileExist configDestinationPath
>  existsAsDir <- doesDirectoryExist configDestinationPath
>  case existsAsFile || existsAsDir of
>   False ->
>    return $ categorizedConfigs
>              {nonActivated
>              = config : nonActivated categorizedConfigs}
>   True -> linkCheck

> linkCheck = do
>  status <- getSymbolicLinkStatus configDestinationPath
>  case isSymbolicLink status of
>   False ->
>    return $ categorizedConfigs
>              {presentAsFile
>              = config : presentAsFile categorizedConfigs}
>   True ->
>    linkDestinationCheck
> linkDestinationCheck = do
>  destination <- readSymbolicLink configDestinationPath
>  linkDestinationCheck' $ splitPath destination
> linkDestinationCheck' splitUpPath@(_:_:_) = do
>  let profilesDir' = joinPath $ (init.init) splitUpPath
>  canonProfilesDir <- canonicalizePath profilesDir
>  canonProfilesDir' <- canonicalizePath profilesDir'
>  case canonProfilesDir == canonProfilesDir' of
>   True ->
>    return $ categorizedConfigs
>              {activatedWithValidSymlink
>              = config : activatedWithValidSymlink categorizedConfigs}
>   False -> linkDestinationCheck' []
> linkDestinationCheck' [] = do
>    return $ categorizedConfigs
>              {presentAsFile
>              = config : presentAsFile categorizedConfigs}

>loadProfile :: FilePath -> FilePath -> String -> IO()
>loadProfile destDir profilesDir profile = isProfilePathDirectory
> where
> profilePath = combine profilesDir profile
> isProfilePathDirectory = do
>   status <- getFileStatus profilePath
>   case isDirectory status of
>    True -> getConfigFilePaths
>    False ->
>     putStrLn $ "The configuration profile directory " ++ profile ++ " found at " ++ profilePath ++ " is not a directory and thus is not a valid profile in the eyes of config-select\n" ++ explanationOfConfigSelector

Look at what config files were selected.

> getConfigFilePaths = do
>   contents' <- getDirectoryContents profilePath
>   let configs = directoryContents contents'

Check if these files exist in the
destination directory.

>   categorizedDestinations <- foldrM (categorizeConfig destDir profilesDir) emptyConfigs configs
>   case categorizedDestinations of
>    ConfigsInDestDir{presentAsFile=presentConfigs@(_:_)} -> backupRuitine presentConfigs
>    ConfigsInDestDir{activatedWithValidSymlink=symlinks} -> deleteSymlinks symlinks configs

> backupRuitine presentConfigs = do
>  putStrLn "Some config files already exist in the destination directory:"
>  mapM_ putStrLn presentConfigs
>  putStrLn "Do you want to back them up by creating a new configuration profile? [y(yes)/H(help)/n(no)]"
>  answer <- getLine
>  case map toLower answer of
>   "y" -> getBackupName presentConfigs
>   "h" -> do
>    putStrLn explanationOfConfigSelector
>    backupRuitine presentConfigs
>   "n" -> return ()
>   _ -> backupRuitine presentConfigs

> getBackupName presentConfigs = do
>  hSetBuffering stdout NoBuffering
>  putStr "Please type a name for your new config profile: "
>  backupProfile <- getLine
>  alreadyExistsFile <- doesFileExist $ combine profilesDir backupProfile
>  alreadyExistsDir <- doesDirectoryExist $ combine profilesDir backupProfile
>  case alreadyExistsDir || alreadyExistsFile of
>   True -> do
>    putStrLn "A config profile of that name already exists."
>    getBackupName presentConfigs
>   False -> createBackup backupProfile presentConfigs

> createBackup backupProfile presentConfigs = do
>  createDirectory $ combine profilesDir backupProfile
>  mapM_ (moveToProfileDir backupProfile) presentConfigs
>  putStrLn $ "Backup created in a new profile named "++ backupProfile ++"."
>  putStrLn "Note that this new profile contains only the files:"
>  mapM putStrLn presentConfigs
>  putStrLn "Any extra config files you would like to include in the profile must be added manualy."
>  askToContinue backupProfile presentConfigs

> moveToProfileDir backupProfile config = do
>  rename old new
>  where
>   old = combine destDir config
>   new = joinPath [profilesDir,backupProfile,config]

> askToContinue backupProfile presentConfigs = do
>  putStrLn $ "Would you like to continue loading the profile you had origionally selected: " ++ profile ++ "? [y/n]"
>  answer <- getLine
>  case map toLower answer of
>   "y" -> loadProfile destDir profilesDir profile -- Start over.
>   "n" -> return () -- Quit.
>   _ -> askToContinue backupProfile presentConfigs

> deleteSymlinks symlinks configs = do
>  mapM_ deleteSymlink symlinks
>  activateConfigs configs
> deleteSymlink symlink = do
>  removeFile symlinkPath
>  where
>   symlinkPath = combine destDir symlink
> activateConfigs configs = do
>  mapM_ activateConfig configs
>  putStrLn $ "The profile " ++ profile ++ " was loaded successfully."
> activateConfig config =
>  createSymbolicLink source dest
>  where
>   source = joinPath [profilesDir,profile,config]
>   dest = combine destDir config

>directoryContents
> = filter
>    $ \x -> not $ (x == ".") || (x == "..")
