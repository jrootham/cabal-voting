module PaperListing exposing (paperListPage)

import Html exposing (Html, div, h3, h5, text, table, thead, th, tr, td, select, option, label, input)
import Html.Attributes exposing (class, value, selected, type_, checked, disabled, name)
import Html.Events exposing (onClick)
import Date

import Types exposing (..)
import Common exposing (normalFlatButton, thinFlatButton, makeLink)

paperListPage : Model -> Html Msg
paperListPage model =
    let
        radioSelected =
            radioBase model.order

        radio =
            radioSelected True

        sumVotes = \ voteList -> List.sum (List.map .votes voteList)

        compare =
            case model.order of
                Title ->
                    totalOrder (\left right -> left.title < right.title)

                Earliest ->
                    totalOrder (\left right -> (Date.toTime left.createdAt) < (Date.toTime right.createdAt))

                Latest ->
                    totalOrder (\left right -> (Date.toTime right.createdAt) < (Date.toTime left.createdAt))

                MostVotes ->
                    totalOrder (\left right -> (sumVotes right.votes) < (sumVotes left.votes))

                LeastVotes ->
                    totalOrder (\left right -> (sumVotes left.votes) < (sumVotes right.votes))

                Submitter ->
                    totalOrder (\left right -> left.submitter < right.submitter)

                Mine ->
                    mineOrder model.name

                Voter ->
                    votes model.voter
    in
        div []
            [ (div [] [ h3 [] [ text (userLine model) ] ])
            , displayAdmin model
            , div [ class "order" ]
                [ text "Order: "
                , radio " Title " Title
                , radio " Earliest " Earliest
                , radio " Latest " Latest
                , radio " Most votes " MostVotes
                , radio " Least votes " LeastVotes
                , radio " Submitter " Submitter
                , radio " My Papers " Mine
                , div [class "group"] 
                    [   
                        radioSelected True " Voter " Voter
                        , select []
                            (List.map
                                (\voter -> option 
                                    [ value voter
                                    , onClick (ChangeVoter voter) 
                                    , selected (voter == model.voter)
                                    ] 
                                    [ text voter ])
                                model.voters
                            )
                    ]
                ]
            , (div []
                    [
                        (normalFlatButton (model.debounce && validateAdd model) Add "Add")
                        ,(normalFlatButton model.debounce Reload "Reload")
                    ]
                )
            , (div []
                [ table []
                    ((thead []
                        [ tr []
                            [ th [] [ text "Submitter" ]
                            , th [] [ text "Contents" ]
                            , th [] [ text "Vote" ]
                            , th [] [ text "Voters" ]
                            ]
                        ]
                     )
                        :: (List.map (displayPaper model) (List.sortWith compare model.papers))
                    )
                ]
              )
            ]

displayAdmin : Model -> Html Msg
displayAdmin model =
    if model.admin then
        div [] [text "Admin"]
    else
        div [] []
        
radioBase : PaperOrder -> Bool -> String -> PaperOrder -> Html Msg
radioBase current enable labelText order =
    label [class "group"]
        [ input
            [ type_ "radio"
            , name "change-order"
            , onClick (ChangeOrder order)
            , checked (current == order)
            , disabled (not enable)
            ]
            []
        , text labelText
        ]
        
voteTable: List Vote -> List (Html Msg)
voteTable votes =
    let
        rawDisplayVotes = \ name votes -> tr [] [ td [class "vote-name"] [text name], td [] [text (toString votes)]]
        displayVotes = \ vote -> rawDisplayVotes vote.name vote.votes
        totalVotes = \ votes -> rawDisplayVotes "Total" (List.sum (List.map .votes votes))
    in
        
    [table [] ((totalVotes votes) :: (List.map displayVotes votes))]

displayPaper : Model -> Paper -> Html Msg
displayPaper model paper =
    let
        testVote = \ vote -> vote.name == model.name

        thisVoterCount = 
            let
                possible =  List.head (List.filter testVote paper.votes)
            in
                case possible of
                    Just vote ->
                        vote.votes
                    Nothing ->
                        0

        belongsTo = model.name == paper.submitter

    in
        tr [ class "entry" ]
            [ td [class "column"]
                [ div []
                    [ div [ class "submitter" ] [ text paper.submitter ]
                    , normalFlatButton belongsTo (DoEdit paper.id) "Edit"
                    , normalFlatButton (model.debounce && belongsTo) (Close paper.id) "Close" 
                    ]
                ]
            , td [class "column"]
                ([ (div [] [ h5 [] [ text paper.title ] ])
                , (div [] [makeLink paper.paper])
                , (div [ class "contents" ] [ text paper.comment ])
                ] ++ (List.map (\ ref-> div [] [makeLink ref.link]) (List.sortBy .index paper.references)))
            , td [class "column", class "vote" ]
                [ div [class "group"]
                    [
                        thinFlatButton (model.debounce && thisVoterCount > 0) (DecrementVote paper.id) "-"
                        , text " "
                        , text (toString thisVoterCount)
                        , text " "
                        , thinFlatButton (model.debounce && voteLimit model thisVoterCount) (IncrementVote paper.id) "+"
                    ]
                ]
            , td [class "column"](voteTable paper.votes)
            ]


countVotes : Model -> Int
countVotes model =
    let
        inner: Vote -> Int -> Int
        inner = \ vote count -> count + vote.votes
        filter : Vote -> Bool
        filter = \ vote -> vote.name == model.name
        outer: Paper -> Int -> Int
        outer = \ paper count -> List.foldl inner count (List.filter filter paper.votes)
    in
        List.foldl outer 0 model.papers

voteLimit : Model -> Int-> Bool
voteLimit model thisVoterCount =
    let
        available = (getMaxVotes model) - (countVotes model)
    in
        (available > 0) && ((getMaxPerPaper model) > thisVoterCount)

validateAdd : Model -> Bool
validateAdd model =
    (getMaxPapers model) > (List.length (List.filter (\ paper -> model.name == paper.submitter) model.papers))            

userLine : Model -> String
userLine model =
    let
        paperCount =
            List.length (List.filter (\paper -> model.name == paper.submitter) model.papers)

        paperString =
            toString paperCount

        maxPaperString =
            toString (getMaxPapers model)

        voteString =
            toString (countVotes model)

        maxVoteString =
            toString (getMaxVotes model)

        submitString =
            " submitted " ++ paperString ++ " of " ++ maxPaperString ++ " possible, "

        votingString =
            " cast  " ++ voteString ++ " of " ++ maxVoteString ++ " possible votes, "

        totalString =
            "out of " ++ (toString (List.length model.papers)) ++ " total."
    in
        "User: " ++ model.name ++ submitString ++ votingString ++ totalString


nameIn : String -> Paper -> Bool
nameIn name paper =
    List.member name (List.map (\ vote -> vote.name) paper.votes)

getVotes : String -> List Vote -> Int
getVotes name voteList =
    let
        entry = List.head (List.filter (\vote -> vote.name == name) voteList)
    in
    case entry of
        Just vote ->
            vote.votes
        
        Nothing ->
            Debug.crash "Should have votes"


compareVotes : String -> List Vote -> List Vote -> Order
compareVotes name left right =
    if getVotes name left == getVotes name right then
        EQ
    else if getVotes name left < getVotes name right then
        GT
    else
        LT


votes : String -> (Paper -> Paper -> Order)
votes name =
    let
        voterIn =
            nameIn name
    in
        \left right ->
            if (voterIn left) && (voterIn right) then
                compareVotes name left.votes right.votes

            else if (not (voterIn left)) && (voterIn right) then
                GT
            else if (voterIn left) && (not (voterIn right)) then
                LT
            else if (not (voterIn left)) && (not (voterIn right)) then
                EQ
            else
                Debug.crash "votes: This should be impossible"


totalOrder : (a -> a -> Bool) -> a -> a -> Order
totalOrder lessThan left right =
    if (lessThan left right) then
        LT
    else if (lessThan right left) then
        GT
    else
        EQ

mineOrder: String -> (Paper -> Paper -> Order)
mineOrder name =
    \left right ->
        if (left.submitter == name) && (right.submitter == name) then
            EQ
        else if (left.submitter == name) && (right.submitter /= name) then
            LT
        else if (left.submitter /= name) && (right.submitter == name) then
            GT
        else if (left.submitter == right.submitter) then
            EQ
        else if (left.submitter < right.submitter) then
            LT
        else if (left.submitter > right.submitter) then
            GT
        else
            Debug.crash "mineOrder Cannot happen"
