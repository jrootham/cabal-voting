module Edit exposing (editPage)

import Common exposing (normalFlatButton, wideFlatButton, widerFlatButton)
import Html exposing (Html, div, input, text, textarea)
import Html.Attributes exposing (class, cols, type_, value)
import Html.Events exposing (onInput)
import Types exposing (..)


editPage : Model -> Html Msg
editPage model =
    case getEdit model of
        Just paper ->
            div []
                [ div [] [ inputDiv "Title: " paper.title InputTitle ]
                , div [] [ editPaperLink paper ]
                , div []
                    [ div [ class "label" ]
                        [ text "Comment: " ]
                    , textarea [ cols 80, onInput InputComment ] [ text paper.comment ]
                    ]
                , div [] [ div [ class "label" ] [ text "References: " ], editReferences paper.id paper.references ]
                , div []
                    [ normalFlatButton model.debounce Save "Save"
                    , normalFlatButton True Cancel "Cancel"
                    ]
                ]

        Nothing ->
            div [] [ text "Paper not found.  Should not occur." ]


editReferences : Int -> List Reference -> Html Msg
editReferences paperId references =
    div []
        [ div [] [ div [] [ wideFlatButton True AddReference "Add reference" ] ]
        , div [] [ div [] (List.map editReference (List.sortBy .index references)) ]
        ]


editLink : (String -> Msg) -> (String -> Msg) -> Link -> Html Msg
editLink makeMessageText makeMessageLink link =
    div []
        [ inputDiv "Link text: " link.text makeMessageText
        , urlDiv "Link: " link.link makeMessageLink
        ]


editReference : Reference -> Html Msg
editReference reference =
    div []
        [ widerFlatButton True (DeleteReference reference.index) "Delete reference"
        , editLink (InputReferenceText reference.index) (InputReferenceLink reference.index) reference.link
        ]


editPaperLink : Paper -> Html Msg
editPaperLink paper =
    editLink InputPaperText InputPaperLink paper.paper


inputDivBase : String -> String -> String -> (String -> Msg) -> Html Msg
inputDivBase typeName label currentValue makeMessage =
    div [] [ div [ class "label" ] [ text label ], input [ type_ typeName, value currentValue, onInput makeMessage ] [] ]


inputDiv =
    inputDivBase "text"


urlDiv =
    inputDivBase "url"
