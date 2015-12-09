-- |
-- Module      :  Handler.EditProfile
-- Copyright   :  © 2015 Mark Karpov
-- License     :  GPL-3
--
-- Maintainer  :  Mark Karpov <markkarpov@openmailbox.org>
-- Stability   :  experimental
-- Portability :  portable
--
-- Edit user profile. Note that admins can edit profile of any user.

{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell   #-}

module Handler.EditProfile
  ( getEditProfileR
  , postEditProfileR )
where

import Helper.Access (userViaSlug)
import Import
import Yesod.Form.Bootstrap3
import qualified Svod as S

-- | Editable pieces of user profile.

data EditProfileForm = EditProfileForm
  { epWebsite :: Maybe Text  -- ^ Website
  , epDesc    :: Maybe Textarea -- ^ Description (“About me”)
  }

-- | Everything user can edit in his profile is on this form. The argument
-- of the function is used to populate default values for the form.

editProfileForm :: User -> Form EditProfileForm
editProfileForm User {..} =
  renderBootstrap3 BootstrapBasicForm $ EditProfileForm
    <$> aopt urlField (withAutofocus $ bfs ("Ваш сайт" :: Text))
      (Just userWebsite)
    <*> aopt textareaField (bfs ("Расскажите о себе" :: Text))
      (Just $ Textarea <$> userDesc)

-- | Serve page containing form that allows to edit user profile.

getEditProfileR :: Text -> Handler Html
getEditProfileR slug' =
  let slug = mkSlug slug'
  in userViaSlug slug $ \user -> do
    (form, enctype) <- generateFormPost . editProfileForm . entityVal $ user
    serveEditProfile slug form enctype

-- | Process submitted form and refresh user's profile.

postEditProfileR :: Text -> Handler Html
postEditProfileR slug' =
  let slug = mkSlug slug'
  in userViaSlug slug $ \user -> do
    ((result, form), enctype) <-
      runFormPost . editProfileForm . entityVal $ user
    case result of
      FormSuccess EditProfileForm {..} -> do
        runDB $ S.editUserProfile
          (entityKey user)
          epWebsite
          (unTextarea <$> epDesc)
        render <- getUrlRender
        let profileUrl = render (UserR slug')
        setMsg MsgSuccess $
          "Профиль пользователя [" <> userName (entityVal user) <>
          "](" <> profileUrl <> ") обновлен успешно."
      _ -> return ()
    serveEditProfile slug form enctype

serveEditProfile :: ToWidget App a
  => Slug              -- ^ Slug used to access the form
  -> a                 -- ^ Form with editable profile parameters
  -> Enctype           -- ^ Encoding type required by the form
  -> Handler Html
serveEditProfile slug form enctype = defaultLayout $ do
  setTitle "Редактирование профиля"
  $(widgetFile "edit-profile")