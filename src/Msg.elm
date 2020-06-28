module Msg exposing(Msg(..), DisplayPage(..), EditPage(..))

type Msg
  = Login (Result Http.Error (Maybe M.User))
  | Load (Result Http.Error M.Data)
  | Display DisplayPage
  | Edit EditPage


type DisplayPage
  = ChangeVoter
  | Add
  | Reload
  | Edit Int
  | Close Int
  | IncrementVote Int
  | DecrementVote Int

type EditPage
  = Goo
