module Main exposing (main)

import Html exposing (Html, div, input, button, text, h1, h2, h3, h5, table, thead, tr, th, td, label, 
    select, option, a, textarea)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Date
import Set
import Config
import Parse exposing (Paper, Link)

import Demo exposing(..)

main =
    Html.program { init = init, view = view, update = update, subscriptions = subscriptions }

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


type Page = Login | List | Edit

-- MODEL


type alias Model =
    { page : Page
    , name : String
    , loginError : String
    , fetchError : String
    , papers : List Paper
    , order : PaperOrder
    , voter : String
    , voters : List String
    , edit : Maybe Paper
    }


init : ( Model, Cmd Msg )
init =
    ( (Model Login "" "" "" [] Title "" [] Nothing), Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = Name String
    | DoLogin
    | ClearLogin
    | ChangeOrder PaperOrder
    | ChangeVoter String
    | FetchResult (Result Http.Error ResponseString)
    | ClearFetch
    | Add
    | DoEdit Int
    | Close Int
    | Cancel

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Name newName ->
            ( { model | name = newName}, Cmd.none)

        DoLogin ->
            if isUser model.name then
                ({model | page = List, papers = getPaperList}, Cmd.none)
            else
                ({model | loginError = "Not a valid user"}, Cmd.none)

        ClearLogin ->
            ( { model | loginError = "" }, Cmd.none )

        FetchResult (Ok response) ->
            updateModel model response

        FetchResult (Err error) ->
            ( { model | fetchError = formatError error }, Cmd.none )

        ClearFetch ->
            ( { model | fetchError = "" }, Cmd.none )

        ChangeOrder newOrder ->
            ( { model | order = newOrder }, Cmd.none )

        ChangeVoter newVoter ->
            ( { model | voter = newVoter }, Cmd.none )

        Add ->
            ({model | page = Edit, edit = Just (newPaper model.name)}, Cmd.none)

        DoEdit id ->
            ({model | page = Edit, edit = getPaper model.papers id}, Cmd.none)

        Close id ->
            ({model | papers = delete model.papers id}, Cmd.none)

        Cancel ->
            ({model | page = List}, Cmd.none)



updateModel : Model -> ResponseString -> ( Model, Cmd Msg )
updateModel model response =
    (model, Cmd.none)

{-    let
        result =
            parse response
    in
        case result of
            Ok data ->
                let
                    papers =
                        data.papers

                    raw =
                        List.foldl (\paper voterList -> List.append voterList paper.votes) [ "" ] papers

                    voters =
                        List.sort (Set.toList (Set.fromList raw))
                in
                    ( { model | papers = papers, voters = voters }, Cmd.none )

            Err error ->
                ( { model | fetchError = error }, Cmd.none )
-}

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
        , case model.page of
            Login ->
                loginPage model

            List ->
                if model.fetchError == "" then
                    div [] [ page model ]
                else
                    div [] [text model.fetchError]

            Edit ->
                editPage model
        ]

editPage : Model -> Html Msg
editPage model = 
    case model.edit of
        Just paper ->            
            div [] 
            [
                div [] [text "Title:", input [value paper.title] []]
                ,div [] [text "Paper:", editLink paper.paper]
                ,div [] [text "Comment:", textarea [] [text paper.comment]]
                ,div [] [text "References:", editReferences paper.references]
                ,div [] 
                [
                    div [class "flat-button", setEnabled True] [text "Save"]
                    ,div [class "flat-button", setEnabled True, onClick Cancel] [text "Cancel"]
                ]
            ]

        Nothing ->
            div [] [text "Paper not found.  Should not occur."]

editReferences : List Link -> Html Msg
editReferences references = 
    div [] 
    [
        div [] [div [class "flat-button", setEnabled True] [text "Add reference"]]
        ,div [] [div [] (List.map editLink references)]
    ]


editLink : Link -> Html Msg
editLink link =
    div []
    [
        div [] [text "Link text", input [value link.text] []]
        , div [] [text "Link:", input[type_ "url", value link.link] []]
    ]


loginPage : Model -> Html Msg
loginPage model =
    div [] 
    
    [ div [class "password-line"] [ input [ placeholder "Name", onInput Name ] [] ]
    , div [class "password-line"] [ div [class "flat-button", setEnabled True, onClick DoLogin ] [ text "Login" ] ]
    , div [class "password-line"] [ text model.loginError ]        
    , div [class "password-line"] [ div [class "flat-button", setEnabled True, onClick ClearLogin ] [ text "Clear error" ] ]
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

makeLink: Link -> Html msg
makeLink link =
    a [(href link.link), (target "_blank")] [text link.text]

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
                    , div [ class "flat-button", setEnabled belongsTo, onClick (DoEdit paper.id)  ] [ text "Edit" ]
                    , div [ class "flat-button", setEnabled belongsTo, onClick (Close paper.id) ] [ text "Close" ]
                    ]
                ]
            , td []
                ([ (div [] [ h5 [] [ text paper.title ] ])
                , (div [] [makeLink paper.paper])
                , (div [ class "contents" ] [ text paper.comment ])
                ] ++ (List.map (\ ref-> div [] [makeLink ref]) paper.references))
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
            , div [] [div [class "flat-button", setEnabled True, onClick Add] [text "Add"]]
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


fetch : String -> Cmd Msg
fetch name =
    let
        mime =
            "application/json"

        url =
            "https://api.github.com/graphql"

        payload = "{}"

        req =
            Http.request
                { method = "POST"
                , headers = []
                , url = url
                , body = Http.stringBody mime payload
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send FetchResult req
