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
        _ = Debug.log "listing papers" model.paperModel.voterList

        radioSelected =
            radioBase (getPaperOrder model)

        radio =
            radioSelected True

        sumVotes = \ voteList -> List.sum (List.map .votes voteList)

        compare =
            case getPaperOrder model of
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
                    case model.currentUser of
                        Just user ->
                            mineOrder user.name

                        Nothing ->
                            totalOrder (\left right -> left.submitter < right.submitter)

                Voter ->
                    votes (getVoter model)
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
                , if model.currentUser /= Nothing then
                    radio " My Papers " Mine
                  else
                    div [class "group"] []
                , div [class "group"] 
                    [   
                        radioSelected True " Voter " Voter
                        , select []
                            (List.map
                                (\voter -> option 
                                    [ value voter
                                    , onClick (ChangeVoter voter) 
                                    , selected (voter == (getVoter model))
                                    ] 
                                    [ text voter ])
                                (getVoterList model)
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
                        :: (List.map (displayPaper model) (List.sortWith compare (getPaperList model)))
                    )
                ]
              )
            ]

displayAdmin : Model -> Html Msg
displayAdmin model =
    case model.currentUser of
        Just user ->
            if user.admin then
                div [] 
                [
                      div [class "group"]  [text "Admin"]
                    , div [class "group"]  [normalFlatButton model.debounce LoadUsers "Users"]
                    , div [class "group"]  [normalFlatButton model.debounce CloseList "Close"]
                    , div [class "group"]  [normalFlatButton model.debounce OpenList "Open"]
                    , div [class "group"]  [normalFlatButton model.debounce UpdateRules "Rules"]
                ]
            else
                div [] []

        Nothing ->
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
        testVote =
            case model.currentUser of
                Just user -> 
                    \ vote -> vote.name == user.name

                Nothing ->
                    \ vote -> False

        thisVoterCount = 
            let
                possible =  List.head (List.filter testVote paper.votes)
            in
                case possible of
                    Just vote ->
                        vote.votes
                    Nothing ->
                        0

        belongsTo = 
            case model.currentUser of
                Just user ->
                    user.name == paper.submitter

                Nothing ->
                    False

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
                        thinFlatButton (canDecrement thisVoterCount model) (DecrementVote paper.id) "-"
                        , text " "
                        , text (toString thisVoterCount)
                        , text " "
                        , thinFlatButton (canIncrement thisVoterCount model) (IncrementVote paper.id) "+"
                    ]
                ]
            , td [class "column"](voteTable paper.votes)
            ]

canDecrement : Int -> Model -> Bool
canDecrement votes model =
    (model.currentUser /= Nothing) && model.debounce &&  votes > 0

canIncrement : Int -> Model -> Bool
canIncrement votes model =
    (model.currentUser /= Nothing) && model.debounce && voteLimit model votes 


countVotes : Model -> Int
countVotes model =
    let
        inner: Vote -> Int -> Int
        inner = \ vote count -> count + vote.votes
        
        filter : Vote -> Bool
        filter = 
            case model.currentUser of
                Just user ->
                    \ vote -> vote.name == user.name

                Nothing ->
                    \ vote -> False

        outer: Paper -> Int -> Int
        outer = \ paper count -> List.foldl inner count (List.filter filter paper.votes)
    in
        List.foldl outer 0 (getPaperList model)

voteLimit : Model -> Int-> Bool
voteLimit model thisVoterCount =
    let
        available = (getMaxVotes model) - (countVotes model)
    in
        (available > 0) && ((getMaxPerPaper model) > thisVoterCount)

validateAdd : Model -> Bool
validateAdd model =
    case model.currentUser of
        Just user ->
            let
                submitterFilter = \ paper -> user.name == paper.submitter
                paperCount = (List.length (List.filter submitterFilter (getPaperList model)))
            in
                    
            (getMaxPapers model) > paperCount

        Nothing -> False

userLine : Model -> String
userLine model =
    case model.currentUser of
        Just user ->
            let
                paperCount =
                    List.length (List.filter (\paper -> user.name == paper.submitter) (getPaperList model))

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
                    "out of " ++ (toString (List.length (getPaperList model))) ++ " total."
            in
                "User: " ++ user.name ++ submitString ++ votingString ++ totalString

        Nothing ->
            (toString (List.length (getPaperList model))) ++ " total papers"


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
