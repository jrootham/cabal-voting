module Wait exposing (waitPage)

import Html exposing (Html, div, h2, text)
import Svg exposing (svg, circle)
import Svg.Attributes exposing (width, height, viewBox, cx, cy, r, fill)

import Types exposing (..)

waitPage: Model -> Html Msg
waitPage model =
    let
        ratio = (toFloat model.countDown) / (toFloat totalCount)            
    in
            
    div [] 
        [ div [] [h2 [] [text "Waiting for Server"]]
        , div [] [text model.errorMessage]
        , div [] [progress ratio]
        ]

progress: Float -> Html Msg
progress ratio =
    svg
        [ width "500", height "500", viewBox "0 0 1000 1000" ]
        [ circle [ cx "500", cy "500", r (toString (500 * ratio)), fill "#87cefa"] [] ]