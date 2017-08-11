module Main exposing (main)

import Html exposing (Html, div, input, button, text, h1, h2, h3, h5, table, thead, tr, th, td, label, select, option)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, on)
import Http
import Date
import Set
import Config
import Payload exposing (..)
import Parse exposing (parse, Paper)


main =
    Html.programWithFlags { init = init, view = view, update = update, subscriptions = subscriptions }



-- Aliases


type alias ResponseString =
    String


type alias Key =
    String



-- Types


type PaperOrder
    = Title
    | Earliest
    | Latest
    | LeastVotes
    | MostVotes
    | Submitter
    | MyVotes
    | Voter



-- MODEL


type alias Model =
    { key : String
    , name : String
    , fetchError : String
    , papers : List Paper
    , order : PaperOrder
    , voter : String
    , voters : List String
    }


init : String -> ( Model, Cmd Msg )
init key =
    ( (Model key "" "" [] Title "" []), githubFetch key )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = ChangeOrder PaperOrder
    | ChangeVoter String
    | FetchResult (Result Http.Error ResponseString)
    | Clear


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchResult (Ok response) ->
            updateModel model response

        FetchResult (Err error) ->
            ( { model | fetchError = formatError error }, Cmd.none )

        Clear ->
            ( { model | fetchError = "" }, Cmd.none )

        ChangeOrder newOrder ->
            ( { model | order = newOrder }, Cmd.none )

        ChangeVoter newVoter ->
            ( { model | voter = newVoter }, Cmd.none )



updateModel : Model -> ResponseString -> ( Model, Cmd Msg )
updateModel model response =
    let
        result =
            parse response
    in
        case result of
            Ok data ->
                let
                    name =
                        data.name

                    papers =
                        data.papers

                    raw =
                        List.foldr (\paper voterList -> List.append voterList paper.votes) [ "" ] papers

                    voters =
                        List.sort (Set.toList (Set.fromList raw))
                in
                    ( { model | name = name, papers = papers, voters = voters }, Cmd.none )

            Err error ->
                ( { model | fetchError = error }, Cmd.none )


formatError : Http.Error -> String
formatError error =
    case error of
        Http.BadUrl url ->
            "Bad URL " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus response ->
            "Bad status:" ++ response.status.message ++ response.body

        Http.BadPayload explain result ->
            "Bad payload" ++ explain


view : Model -> Html Msg
view model =
    div [ class "outer" ]
        [ div [] [ h1 [] [ text "Cabal Voting System" ] ]
        , if model.fetchError == "" then
            div [] [ page model ]
        else
            div [] [text model.fetchError]
        ]


checkVote : String -> String -> Bool
checkVote login vote =
    login == vote


setEnabled : Bool -> Html.Attribute msg
setEnabled enabled =
    if enabled then
        class "flat-enabled"
    else
        class "flat-disabled"


displayPaper : Model -> Bool -> Paper -> Html Msg
displayPaper model votable paper =
    let
        testVote =
            checkVote model.name

        on =
            List.any testVote paper.votes

        belongsTo =
            model.name == paper.submitter
    in
        tr [ class "entry" ]
            [ td []
                [ div []
                    [ div [ class "submitter" ] [ text paper.submitter ]
                    , div [ class "flat-button", setEnabled belongsTo ] [ text "Edit" ]
                    ]
                ]
            , td []
                [ (div [] [ h5 [] [ text paper.title ] ])
                , (div [ class "contents" ] [ text paper.body ])
                ]
            , td [ class "vote" ]
                [ label []
                    [ input
                        [ type_ "checkbox"
                        , checked on
                        , disabled (not (on || votable))
                        ]
                        []
                    , text "Vote"
                    ]
                ]
            , td [] (List.map (\login -> div [] [ text login ]) paper.votes)
            ]


countVotes : Model -> Int
countVotes model =
    let
        testVote =
            checkVote model.name

        pickVote =
            \issue -> List.any testVote issue.votes
    in
        List.length (List.filter pickVote model.papers)


voteLimit : Model -> Bool
voteLimit model =
    Config.maxVotes >= countVotes model


userLine : Model -> String
userLine model =
    let
        paperCount =
            List.length (List.filter (\paper -> model.name == paper.submitter) model.papers)

        paperString =
            toString paperCount

        maxPaperString =
            toString Config.maxPapers

        voteString =
            toString (countVotes model)

        maxVoteString =
            toString Config.maxVotes

        submitString =
            " submitted " ++ paperString ++ " of " ++ maxPaperString ++ " possible, "

        votingString =
            " voted for  " ++ voteString ++ " of " ++ maxVoteString ++ " possible, "

        totalString =
            "out of " ++ (toString (List.length model.papers)) ++ " total."
    in
        "User: " ++ model.name ++ submitString ++ votingString ++ totalString


nameIn : String -> Paper -> Bool
nameIn name paper =
    List.member name paper.votes


votes : String -> (Paper -> Paper -> Order)
votes name =
    let
        voterIn =
            nameIn name
    in
        \left right ->
            if (voterIn left) && (voterIn right) then
                EQ
            else if (not (voterIn left)) && (voterIn right) then
                GT
            else if (voterIn left) && (not (voterIn right)) then
                LT
            else if (not (voterIn left)) && (not (voterIn right)) then
                EQ
            else
                Debug.crash "This should be impossible"


totalOrder : (a -> a -> Bool) -> a -> a -> Order
totalOrder lessThan left right =
    if (lessThan left right) then
        LT
    else if (lessThan right left) then
        GT
    else
        EQ


page : Model -> Html Msg
page model =
    let
        radioSelected =
            radioBase model.order

        radio =
            radioSelected True

        compare =
            case model.order of
                Title ->
                    totalOrder (\left right -> left.title < right.title)

                Earliest ->
                    totalOrder (\left right -> (Date.toTime left.createdAt) < (Date.toTime right.createdAt))

                Latest ->
                    totalOrder (\left right -> (Date.toTime right.createdAt) < (Date.toTime left.createdAt))

                MostVotes ->
                    totalOrder (\left right -> (List.length right.votes) < (List.length left.votes))

                LeastVotes ->
                    totalOrder (\left right -> (List.length left.votes) < (List.length right.votes))

                Submitter ->
                    totalOrder (\left right -> left.submitter < right.submitter)

                MyVotes ->
                    votes model.name

                Voter ->
                    votes model.voter
    in
        div []
            [ (div [] [ h3 [] [ text (userLine model) ] ])
            , div [ class "order" ]
                [ text "Order: "
                , radio " Title " Title
                , radio " Earliest " Earliest
                , radio " Latest " Latest
                , radio " Most votes " MostVotes
                , radio " Least votes " LeastVotes
                , radio " Submitter " Submitter
                , radio " My votes " MyVotes
                , radioSelected (not (model.voter == "")) " Voter " Voter
                , select []
                    (List.map
                        (\voter -> option [ value voter, onClick (ChangeVoter voter) ] [ text voter ])
                        model.voters
                    )
                ]
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
                        :: (List.map (displayPaper model (voteLimit model)) (List.sortWith compare model.papers))
                    )
                ]
              )
            ]


radioBase : PaperOrder -> Bool -> String -> PaperOrder -> Html Msg
radioBase current enable labelText order =
    label []
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



-- Commands


githubFetch : Key -> Cmd Msg
githubFetch key =
    let
        headers =
            [ Http.header "Authorization" ("bearer" ++ key) ]

        mime =
            "application/json"

        url =
            "https://api.github.com/graphql"

        payload =
            makePayload Config.owner Config.repository

        req =
            Http.request
                { method = "POST"
                , headers = headers
                , url = url
                , body = Http.stringBody mime payload
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send FetchResult req
