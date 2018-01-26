module AdminPaper exposing (openList, closedList)

import Html exposing (Html, div, text, table, tr, td)
import Date

import Types exposing (..)
import Common exposing (normalFlatButton, flipOrder)

openList: Model -> Html Msg
openList model =
    case model.openPaperList of
        Just paperList ->
            div [] 
                [ div [] [normalFlatButton model.debounce ShutOpenList "Close Page"]
                , div [] [text "Ordered by most votes"]
                , div [] [table [] (openListRows model paperList)]
                ]

        Nothing ->
            div [] [text "No openPaperList.  should not occur"]

openListRows : Model -> List OpenPaper -> List (Html Msg)
openListRows model paperList =
    let
        comp = \left right -> flipOrder (compare left.totalVotes right.totalVotes)            
    in
            
    List.map (openRow model) (List.sortWith comp paperList)

openRow : Model -> OpenPaper -> Html Msg
openRow model paper =
    tr [] 
        [ td [] [div [] [div [] [text paper.title], div [] [text paper.comment]]]
        , td [] [normalFlatButton model.debounce (AdminClose paper.id) "Close Paper"]
        ]

closedList: Model -> Html Msg
closedList model =
    case model.closedPaperList of
        Just paperList ->
            div [] 
                [ div [] [normalFlatButton model.debounce ShutClosedList "Close Page"]
                , div [] [text "Ordered by most recent date closed"]
                , div [] [table [] (closedListRows model paperList)]
                ]

        Nothing ->
            div [] [text "No closedPaperList.  should not occur"]

closedListRows : Model -> List ClosedPaper -> List (Html Msg)
closedListRows model paperList =
    let
        comp = \left right -> flipOrder (compare (Date.toTime left.closedAt) (Date.toTime right.closedAt))            
    in
            
    List.map (closedRow model) (List.sortWith comp paperList)

closedRow : Model -> ClosedPaper -> Html Msg
closedRow model paper =
    tr [] 
        [ td [] [div [] [div [] [text paper.title], div [] [text paper.comment]]]
        , td [] [normalFlatButton model.debounce (AdminOpen paper.id) "Open Paper"]
        ]
