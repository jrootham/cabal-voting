module Login exposing (loginPage)

import Common exposing (normalFlatButton, wideFlatButton)
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder)
import Html.Events exposing (onInput)
import Types exposing (..)


loginPage : Model -> Html Msg
loginPage model =
    let
        canLogin =
            (model.currentUser /= Nothing) && model.debounce
    in
    div []
        [ div [ class "password-line" ] [ input [ placeholder "Name", onInput Name ] [] ]
        , div [ class "password-line" ] [ normalFlatButton canLogin StartLogin "Login" ]
        , div [ class "password-line" ] [ normalFlatButton model.debounce Guest "Guest" ]
        , div [ class "password-line" ] [ text model.errorMessage ]
        , div [ class "password-line" ] [ wideFlatButton True ClearError "Clear error" ]
        ]
