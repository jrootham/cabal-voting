module Login exposing (loginPage)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder)
import Html.Events exposing (onInput)

import Types exposing (..)
import Common exposing (normalFlatButton, wideFlatButton)

loginPage : Model -> Html Msg
loginPage model =
    div [] 
    
    [ div [class "password-line"] [ input [ placeholder "Name", onInput Name ] [] ]
    , div [class "password-line"] [ normalFlatButton model.debounce StartLogin "Login"]
    , div [class "password-line"] [ text model.errorMessage ]        
    , div [class "password-line"] [ wideFlatButton True ClearFetch "Clear error" ]
    ]
    
