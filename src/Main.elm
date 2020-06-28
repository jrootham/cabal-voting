module Main exposing (main)

import Maybe exposing(withDefault)
import Time
import Task
import Browser
import Http
import Html as H
import Html.Attributes as A

import Common as C
import Model as M
import DisplayPage
import EditPage
import Update as U

-- MAIN

main : Program String M.Model M.Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


init : String -> ( M.Model, Cmd M.Msg )
init token =
  ( M.initialModel
  , login token
  )

login : String -> Cmd M.Msg
login token = 
  Http.get {url = "login?server-token=" ++ token , expect = Http.expectJson M.Login M.loginDecoder}

-- UPDATE

update : M.Msg -> M.Model -> ( M.Model, Cmd M.Msg )
update msg model =
  case msg of
    M.Login result -> (U.updateLogin model result, C.load)

    M.Load response -> (U.handleResponse model response, Cmd.none)

    M.ClearError -> (M.clearError model, Cmd.none)

    M.ChangeOrder paperOrder -> (M.setOrder paperOrder model, Cmd.none)

    M.ChangeVoter user -> (M.setSortByVoter user model, Cmd.none)

    M.Reload -> (M.setDebounce False model, C.load)

    M.Close paper -> U.launchClose model paper

    M.DoClose time -> U.close model time

    M.IncrementVote paper -> U.increment model paper

    M.DecrementVote paper -> U.decrement model paper

    M.Add -> (M.setDebounce False model, Task.perform M.NewPaper Time.now)

    M.NewPaper time -> (U.addPaper model time, Cmd.none)

    M.DoEdit paper -> (U.editPaper model paper, Cmd.none)

    M.Cancel -> (U.cancel model, Cmd.none)

    M.InputTitle title -> (U.updatePaper U.updateTitle title model, Cmd.none)

    M.InputComment comment -> (U.updatePaper U.updateComment comment model, Cmd.none)

    M.Save -> U.save model

    M.AddReference -> (U.addReference model, Cmd.none)
    
    M.DeleteReference reference -> (U.updatePaper U.deleteReference reference model, Cmd.none)
    
    M.InputReferenceText reference text -> 
      (U.updateReference U.setReferenceText text reference model, Cmd.none)
    
    M.InputReferenceLink reference link -> 
      (U.updateReference U.setReferenceLink link reference model, Cmd.none)
    
    M.InputPaperLink link -> (U.updatePaper U.updatePaperLink link model, Cmd.none)


-- VIEW

view : M.Model -> H.Html M.Msg
view model =
    H.div [ A.class "outer" ]
        [
          (H.div [] [H.h1 [] [H.text "Cabal Voting System"]])

          ,case (M.getError model) of
            Nothing ->
              case (M.getPage model) of
                M.Display ->
                  DisplayPage.page model

                M.Edit ->
                  EditPage.page model

            Just error ->
              errorPage model error
        ]


errorPage : M.Model -> M.Error -> H.Html M.Msg
errorPage model error =
  case error of
    M.HttpError httpErrorType ->
      case httpErrorType of
        Http.BadUrl reason ->
          showMessage model ("Bad URL " ++ reason)

        Http.Timeout ->
          showMessage model "Timeout"

        Http.NetworkError ->
          showMessage model "Network error"

        Http.BadStatus status ->
          showMessage model ("Status " ++ String.fromInt status)

        Http.BadBody reason ->
          showMessage model ("Bad body " ++ reason)

    M.LocalError message ->
      showMessage model message

    M.RemoteError message ->
      showMessage model message

showMessage : M.Model -> String -> H.Html M.Msg
showMessage model message =
  H.div []
    [ H.div [] [H.text message]
    , C.normalFlatButton (M.getDebounce model) M.ClearError "Clear error"
    ]

-- SUBSCRIPTIONS

subscriptions : M.Model -> Sub M.Msg
subscriptions _ =
  Sub.none
