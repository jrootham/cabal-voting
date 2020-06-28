module Common exposing ( load, expect, flatButton, makeLink
  , normalFlatButton, thinFlatButton, wideFlatButton, widerFlatButton
  )

import Http
import Html as H
import Html.Attributes as A
import Html.Events as E

import Model as M

load : Cmd M.Msg
load =
  Http.get {url = "load" , expect = expect}

expect = 
  Http.expectJson M.Load M.responseDecoder

flatButton : String -> Bool -> msg -> String -> H.Html msg
flatButton otherClass enabled click label =
  let
    others =
      if enabled then
        [ A.class "flat-enabled", E.onClick click ]

      else
      [ A.class "flat-disabled" ]
  in
  H.button (List.append [ A.class "flat-button", A.class otherClass ] others) [ H.text label ]


normalFlatButton =
  flatButton "normal"


wideFlatButton =
  flatButton "wide"


widerFlatButton =
  flatButton "wider"


thinFlatButton =
  flatButton "thin"


makeLink : String -> String -> H.Html msg
makeLink text link =
  H.a [ A.href link, A.target "_blank" ] [ H.text text ]

