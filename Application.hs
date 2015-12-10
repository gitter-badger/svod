-- |
-- Module      :  Application
-- Copyright   :  © 2015 Mark Karpov
-- License     :  GPL-3
--
-- Maintainer  :  Mark Karpov <markkarpov@openmailbox.org>
-- Stability   :  experimental
-- Portability :  portable
--
-- Second half of business started in "Foundation".

{-# LANGUAGE NoImplicitPrelude    #-}
{-# LANGUAGE TemplateHaskell      #-}
{-# LANGUAGE ViewPatterns         #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Application
  ( -- * High-level boilerplate
    getApplicationDev
  , appMain
  , develMain
  , makeFoundation
  , makeLogWare
  -- * Functions for use in development with GHCi
  , handler
  , db )
where

import Control.Monad.Logger (liftLoc, runLoggingT)
import Database.Persist.Postgresql
  ( createPostgresqlPool
  , pgConnStr
  , pgPoolSize
  , runSqlPool )
import Import
import Language.Haskell.TH.Syntax (qLocation)
import Network.Wai (Middleware)
import Network.Wai.Handler.Warp
  ( Settings
  , defaultSettings
  , defaultShouldDisplayException
  , runSettings
  , setHost
  , setOnException
  , setPort )
import Network.Wai.Middleware.RequestLogger
  ( Destination (Logger)
  , IPAddrSource (..)
  , OutputFormat (..)
  , destination
  , mkRequestLogger
  , outputFormat )
import Path (fromRelDir)
import System.Log.FastLogger
  ( defaultBufSize
  , newStdoutLoggerSet
  , toLogStr )

import Handler.Administrative
import Handler.ApproveRelease
import Handler.ChangePassword
import Handler.Common
import Handler.DeleteRelease
import Handler.EditProfile
import Handler.EditRelease
import Handler.FollowUser
import Handler.Home
import Handler.Info
import Handler.Login
import Handler.Logout
import Handler.Notifications
import Handler.Register
import Handler.RejectRelease
import Handler.Release
import Handler.Releases
import Handler.StarRelease
import Handler.SubmitRelease
import Handler.User
import Handler.Users
import Handler.Verify

mkYesodDispatch "App" resourcesApp

-- | This function allocates resources (such as a database connection pool),
-- performs initialization and returns a foundation datatype value. This is
-- also the place to put migrate statements to have automatic database
-- migrations handled by Yesod.

makeFoundation :: AppSettings -> IO App
makeFoundation appSettings = do
  appHttpManager <- newManager
  appLogger <- newStdoutLoggerSet defaultBufSize >>= makeYesodLogger
  appStatic <-
    (if appMutableStatic appSettings then staticDevel else static)
    (fromRelDir . appStaticDir $ appSettings)
  appPocket <- atomically . newTVar . Pocket $ ()

  -- We need a log function to create a connection pool. We need a
  -- connection pool to create our foundation. And we need our foundation to
  -- get a logging function. To get out of this loop, we initially create a
  -- temporary foundation without a real connection pool, get a log function
  -- from there, and then create the real foundation. Oh my.

  let mkFoundation appConnPool = App {..}
      tempFoundation = mkFoundation $ error "connPool forced in tempFoundation"
      logFunc        = messageLoggerSource tempFoundation appLogger

  -- Create the database connection pool
  pool <- flip runLoggingT logFunc $ createPostgresqlPool
    (pgConnStr  $ appDatabaseConf appSettings)
    (pgPoolSize $ appDatabaseConf appSettings)

  -- Perform database migration using our application's logging settings.
  runLoggingT (runSqlPool (runMigration migrateAll) pool) logFunc

  -- Return the foundation
  return (mkFoundation pool)

-- | Convert our foundation to a WAI Application by calling @toWaiAppPlain@
-- and applying some additional middlewares.

makeApplication :: App -> IO Application
makeApplication foundation = do
  logWare <- makeLogWare foundation
  -- Create the WAI application and apply middlewares
  appPlain <- toWaiAppPlain foundation
  return $ logWare $ defaultMiddlewaresNoLogging appPlain

makeLogWare :: App -> IO Middleware
makeLogWare foundation =
  mkRequestLogger def
    { outputFormat =
        if appDetailedRequestLogging (appSettings foundation)
        then Detailed True
        else Apache $
          if appIpFromHeader (appSettings foundation)
          then FromFallback
          else FromSocket
    , destination = Logger . loggerSet . appLogger $ foundation
    }

-- | Warp settings for the given foundation value.

warpSettings :: App -> Settings
warpSettings foundation =
    setPort (appPort $ appSettings foundation)
  $ setHost (appHost $ appSettings foundation)
  $ setOnException (\_req e ->
      when (defaultShouldDisplayException e) $ messageLoggerSource
          foundation
          (appLogger foundation)
          $(qLocation >>= liftLoc)
          "yesod"
          LevelError
          (toLogStr $ "Exception from Warp: " ++ show e))
    defaultSettings

-- | For Yesod devel, return the Warp settings and WAI Application.

getApplicationDev :: IO (Settings, Application)
getApplicationDev = do
  settings <- getAppSettings
  foundation <- makeFoundation settings
  wsettings <- getDevSettings $ warpSettings foundation
  app <- makeApplication foundation
  return (wsettings, app)

getAppSettings :: IO AppSettings
getAppSettings = loadAppSettings [configSettingsYml] [] useEnv

-- | @main@ function for use by Yesod devel.

develMain :: IO ()
develMain = develMainHelper getApplicationDev

-- | The @main@ function for an executable running this site.

appMain :: IO ()
appMain = do
  settings   <- loadAppSettingsArgs [configSettingsYmlValue] useEnv
  foundation <- makeFoundation settings
  app        <- makeApplication foundation
  runSettings (warpSettings foundation) app

----------------------------------------------------------------------------
-- Functions for use in development with GHCi

-- | Run a handler.

handler :: Handler a -> IO a
handler h = do
  foundation <- getAppSettings >>= makeFoundation
  unsafeHandler foundation h

-- | Run DB queries.

db :: ReaderT SqlBackend (HandlerT App IO) a -> IO a
db = handler . runDB
