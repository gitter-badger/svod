-- |
-- Module      :  Widget.DngButton
-- Copyright   :  © 2015–2016 Mark Karpov
-- License     :  GNU GPL version 3
--
-- Maintainer  :  Mark Karpov <markkarpov@openmailbox.org>
-- Stability   :  experimental
-- Portability :  portable
--
-- Configurable widget providing “dangerous buttons” — buttons that send PUT
-- and DELETE requests via AJAX. The widget also asks to confirm every
-- action initiated with it, because these actions often have serious
-- repercussions.

{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell   #-}

module Widget.DngButton
  ( BtnType (..)
  , dngButtonW )
where

import Helper.Rendering (toJSONId)
import Import
import qualified Data.Text.Encoding as TE

-- | This controls appearance of buttons generated by 'dngButtonW' widget.

data BtnType
  = BtnDefault
  | BtnPrimary
  | BtnSuccess
  | BtnInfo
  | BtnWarning
  | BtnDanger
  | BtnLink

-- | Generate button to execute a dangerous action. If identifier of text
-- area is supplied (fourth argument), then add @\"message\"@ parameter with
-- that text added.

dngButtonW
  :: BtnType           -- ^ Control appearance of generated button
  -> Text              -- ^ Button title
  -> Text              -- ^ HTTP method to use
  -> Maybe Text        -- ^ Optional identifier of text area with message
  -> Route App         -- ^ Route
  -> Widget            -- ^ Button widget
dngButtonW btnType title method mtext route = do
  buttonId  <- newIdent
  addScript (StaticR js_cookie_js)
  $(widgetFile "dng-button")

-- | For internal usage only. Convert 'BtnType' to name of corresponding
-- Bootstrap 3 class.

btnTypeToClass :: BtnType -> Text
btnTypeToClass BtnDefault = "btn-default"
btnTypeToClass BtnPrimary = "btn-primary"
btnTypeToClass BtnSuccess = "btn-success"
btnTypeToClass BtnInfo    = "btn-info"
btnTypeToClass BtnWarning = "btn-warning"
btnTypeToClass BtnDanger  = "btn-danger"
btnTypeToClass BtnLink    = "btn-link"
