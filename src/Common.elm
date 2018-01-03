module Common exposing (flatButton, normalFlatButton, wideFlatButton, widerFlatButton, thinFlatButton, makeLink)

import Html exposing (Html, a, button, text)
import Html.Attributes  exposing (class, href, target)
import Html.Events  exposing (onClick)

import Types exposing (..)

flatButton : String -> Bool -> Msg -> String -> Html Msg
flatButton otherClass enabled click label =
    let
        others = 
            if enabled then
                [class "flat-enabled", onClick click ]        
            else
                [class "flat-disabled"]
    in
            
    button (List.append [class "flat-button", class otherClass] others) [text label]

normalFlatButton = flatButton "normal"
wideFlatButton = flatButton "wide"
widerFlatButton = flatButton "wider"
thinFlatButton = flatButton "thin"

makeLink: Link -> Html msg
makeLink link =
    a [(href link.link), (target "_blank")] [text link.text]

