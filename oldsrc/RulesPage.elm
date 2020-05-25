module RulesPage exposing (editRules)

import Common exposing (normalFlatButton)
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, type_, value)
import Html.Events exposing (onInput)
import Types exposing (..)


editRules : Model -> Html Msg
editRules model =
    case model.editRules of
        Just rules ->
            div []
                [ div [] [ text "Rules" ]
                , div [] [ text model.errorMessage ]
                , buttons model
                , inputRules model rules
                ]

        Nothing ->
            div [] [ text "No rules.  Should not happen" ]


buttons : Model -> Html Msg
buttons model =
    div []
        [ div [ class "group" ] [ normalFlatButton model.debounce ShutRules "Close" ]
        , div [ class "group" ] [ normalFlatButton model.debounce SaveRules "Save" ]
        ]


inputRules : Model -> RulesBuffer -> Html Msg
inputRules model rules =
    div []
        [ div [] [ text "Maximum papers", input [ type_ "text", onInput MaxPapers, value rules.maxPapers ] [] ]
        , div [] [ text "Maximum votes ", input [ type_ "text", onInput MaxVotes, value rules.maxVotes ] [] ]
        , div []
            [ text "Maximum votes per paper"
            , input [ type_ "text", onInput MaxPerPaper, value rules.maxPerPaper ] []
            ]
        ]
