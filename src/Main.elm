module Main exposing (..)

import Html exposing (Html, div, input, button, text, h1, table, tr, td, label, fieldset)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Date
import BasicAuth exposing (buildAuthorizationHeader)
import Json.Decode exposing (Decoder, decodeString, at, int, field, string)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode exposing (..)
import Config
import Payload exposing (..)
import Parse exposing (parse, Paper)


main =
    Html.program { init = init, view = view, update = update, subscriptions = subscriptions }



-- Aliases


type alias ResponseString =
    String


type alias Login =
    String


type alias Password =
    String

-- Types

type PaperOrder 
    = Title | Earliest | Latest | LeastVotes | MostVotes | Submittor

-- MODEL


type alias Model =
    { loggedin : Bool
    , name : String
    , password : String
    , loginError : String
    , papers : List Paper
    , order : PaperOrder
    }


init : ( Model, Cmd Msg )
init =
    ( (Model False "" "" "" [] Title), Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = Name String
    | Password String
    | Login
    | LoginResult (Result Http.Error String)
    | Clear
    | ChangeOrder PaperOrder


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Name newname ->
            ( { model | name = newname }, Cmd.none )

        Password newpassword ->
            ( { model | password = newpassword }, Cmd.none )

        Login ->
            ( model, githubLogin model.name model.password )

        LoginResult (Ok response) ->
            updateModel model response

        LoginResult (Err error) ->
            ( { model | loginError = formatError error }, Cmd.none )

        Clear ->
            ( { model | loginError = "" }, Cmd.none )

        ChangeOrder newOrder ->
            ( { model | order = newOrder}, Cmd.none )


updateModel : Model -> ResponseString -> ( Model, Cmd Msg )
updateModel model response =
    let
        result =
            parse response
    in
        case result of
            Ok papers ->
                ( { model | loggedin = True, papers = papers }, Cmd.none )

            Err error ->
                ( { model | loginError = error }, Cmd.none )


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
    div []
        [ div [] [ h1 [] [ text "Cabal Voting System" ] ]
        , div []
            [ if model.loggedin then
                loggedinPage model
              else
                passwordPage model
            ]
        ]


passwordPage : Model -> Html Msg
passwordPage model =
    div []
        [ div [] [ text "Use github user name and password" ]
        , div [] [ input [ placeholder "Name", onInput Name ] [] ]
        , div [] [ input [ type_ "password", placeholder "Password", onInput Password ] [] ]
        , div [] [ button [ onClick Login ] [ text "Login" ] ]
        , div [] [ text model.loginError ]
        , div [] [ button [ onClick Clear ] [ text "Clear error" ] ]
        ]


checkVote : String -> String -> Bool
checkVote login vote =
    login == vote


displayPaper : Model -> Bool -> Paper -> Html Msg
displayPaper model votable paper =
    let
        testVote =
            checkVote model.name

        on =
            List.any testVote paper.votes
    in
        tr []
            [ td []
                [ (div [] [ text paper.title ])
                , (div [] [ text paper.body ])
                ]
            , td []
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
            List.length (List.filter (\paper -> model.name == paper.submittor) model.papers)

        paperString =
            toString paperCount

        maxPaperString =
            toString Config.maxPapers

        voteString =
            toString (countVotes model)

        maxVoteString =
            toString Config.maxVotes

        submitString =
            " submitted " ++ paperString ++ " of " ++ maxPaperString ++ " possible papers, "

        votingString =
            " voted for  " ++ voteString ++ " of " ++ maxVoteString ++ " possible papers."
    in
        "User: " ++ model.name ++ submitString ++ votingString

totalOrder: (a -> a -> Bool) -> a -> a -> Order
totalOrder lessThan left right =
    if (lessThan left right) then
        LT
    else if (lessThan right left) then
        GT
    else
        EQ

loggedinPage : Model -> Html Msg
loggedinPage model =
    let
        radio = radioBase model.order
        compare = 
            (totalOrder 
                (case model.order of
                    Title ->
                        \ left right -> left.title < right.title
                    Earliest ->
                        \ left right -> (Date.toTime left.createdAt) < (Date.toTime right.createdAt)
                    Latest ->
                        \ left right -> (Date.toTime right.createdAt) < (Date.toTime left.createdAt)
                    MostVotes -> 
                        \ left right -> (List.length right.votes) < (List.length left.votes)
                    LeastVotes -> 
                        \ left right -> (List.length left.votes) < (List.length right.votes)
                    Submittor ->
                        \ left right -> left.submittor < right.submittor
                )
            )
    in        
        div []
            [ (div [] [ text (userLine model) ])
            ,div []
                [text "Order "
                , radio " Title " Title
                , radio " Earliest " Earliest
                , radio " Latest " Latest
                , radio " Most votes " MostVotes
                , radio " Least votes " LeastVotes
                , radio " Submittor " Submittor
                ]   
            , (div [] 
                [ 
                    table [] 
                        (List.map (displayPaper model (voteLimit model)) (List.sortWith compare model.papers)) 
                ])
        ]

radioBase : PaperOrder -> String -> PaperOrder -> Html Msg
radioBase current value order =
  label [] 
    [ input 
        [ type_ "radio"
        , name "change-order"
        , onClick (ChangeOrder order)
        , checked (current == order) 
        ] 
        []
    , text value
    ]


-- Commands


githubLogin : Login -> Password -> Cmd Msg
githubLogin login password =
    let
        header =
            [ buildAuthorizationHeader login password ]

        mime =
            "application/json"

        url =
            "https://api.github.com/graphql"

        payload =
            makePayload Config.owner Config.repository

        req =
            Http.request
                { method = "POST"
                , headers = header
                , url = url
                , body = Http.stringBody mime payload
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send LoginResult req
