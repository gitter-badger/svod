-- |
-- Module      :  Handler.Approve
-- Copyright   :  © 2015 Mark Karpov
-- License     :  GPL-3
--
-- Maintainer  :  Mark Karpov <markkarpov@openmailbox.org>
-- Stability   :  experimental
-- Portability :  portable
--
-- Approve submitted release.

{-# LANGUAGE NoImplicitPrelude #-}

module Handler.Approve
  ( postApproveR )
where

import Import

-- | Approve submitted release. Only admins can do that.

postApproveR :: Handler Html
postApproveR = undefined
