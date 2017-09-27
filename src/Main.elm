module Main exposing (main)

import Html exposing (Html, div, input, button, text, h1, h2, h3, h5, table, thead, tr, th, td, label, 
    select, option, a, textarea)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Date
import Set
import Config
import Parse exposing (Paper, Reference, Link, Vote, parse)
import Payload exposing (loginPayload, paperPayload, votePayload,closePayload)

import Demo exposing(..)

main =
    Html.program { init = init, view = view, update = update, subscriptions = subscriptions }

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
    , errorMessage : String
    , papers : List Paper
    , order : PaperOrder
    , voter : String
    , voters : List String
    , edit : Maybe Paper
    , debounce : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( (Model Login "" "" [] Title "" [] Nothing True), Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE

type Msg
    = Name String
    | StartLogin
    | Add
    | ChangeOrder PaperOrder
    | ChangeVoter String
    | DecrementVote Int
    | IncrementVote Int
    | FetchResult (Result Http.Error String)
    | ClearFetch
    | DoEdit Int
    | Close Int
    | InputTitle String
    | InputPaperText String
    | InputPaperLink String
    | InputComment String
    | AddReference
    | DeleteReference Int
    | InputReferenceText Int String
    | InputReferenceLink Int String
    | Save
    | Cancel

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
--  Login page updates

        Name newName ->
            ( { model | name = newName}, Cmd.none)

        StartLogin ->
            ({model | debounce = False}, fetch (loginPayload model.name))

-- fetch 

        FetchResult (Ok response) ->
            (debounce (updateModel model response), Cmd.none)

        FetchResult (Err error) ->
            ( { model | errorMessage = formatError error, debounce = True }, Cmd.none )

        ClearFetch ->
            ( { model | errorMessage = "" }, Cmd.none )

--  List page updates

        Add ->
            ({model | page = Edit, edit = Just (newPaper model.name)}, Cmd.none)

        ChangeOrder newOrder ->
            ( { model | order = newOrder }, Cmd.none )

        ChangeVoter newVoter ->
            ( { model | voter = newVoter }, Cmd.none )

        DoEdit id ->
            ({model | page = Edit, edit = getPaper model.papers id}, Cmd.none)

        Close id ->
            ({model | debounce = False}, fetch (closePayload model.name id))

        IncrementVote id ->
            ({model | debounce = False}, fetch (votePayload model.name id 1))

        DecrementVote id ->
            ({model | debounce = False}, fetch (votePayload model.name id -1))

--  Edit page updates

        InputTitle newTitle ->
            ({model | edit = makeNewTitle model.edit newTitle}, Cmd.none)
        
        InputPaperText newText ->
            ({model | edit = makeNewPaperText model.edit newText}, Cmd.none)
        
        InputPaperLink newLink ->
            ({model | edit = makeNewPaperLink model.edit newLink}, Cmd.none)
        
        InputComment newComment ->
            ({model | edit = makeNewComment model.edit newComment}, Cmd.none)
        
        AddReference ->
            ({model | edit = addReference model.edit}, Cmd.none)
        
        DeleteReference referenceIndex ->
            ({model | edit = deleteReference model.edit referenceIndex}, Cmd.none)
        
        InputReferenceText referenceIndex newText ->
            ({model | edit = makeNewReferenceText model.edit referenceIndex newText}, Cmd.none)
        
        InputReferenceLink referenceIndex newLink ->
            ({model | edit = makeNewReferenceLink model.edit referenceIndex newLink}, Cmd.none)
        
        Save ->
            case model.edit of
                Just paper ->
                    ({model | debounce = False}, fetch (paperPayload model.name paper))
                Nothing ->
                    ({model | errorMessage = "No paper.  Should not happen"}, Cmd.none)

        Cancel ->
            ({model | page = List, edit = Nothing}, Cmd.none)



getVoters : List Paper -> List String
getVoters paperList = 
    let
        insert : Vote -> (Set.Set String) -> Set.Set String
        insert = \ vote nameSet -> Set.insert vote.name nameSet
        inner:  (List Vote) -> (Set.Set String) -> Set.Set String
        inner = \ voteList nameSet-> List.foldl insert nameSet voteList
        nameSet = List.foldl (\ paper nameSet-> inner paper.votes nameSet) (Set.fromList [""]) paperList 
    in
        Set.toList nameSet


debounce : Model -> Model
debounce model = 
    {model | debounce = True}

updateModel : Model -> String -> Model
updateModel model response =
    case parse response of
        Ok errorAndPapers ->
            let
                error = errorAndPapers.error
                papers = errorAndPapers.paperList
            in
                if error == "" then
                    { model | errorMessage = "", page = List, papers = papers, voters = getVoters papers}
                else
                    {model | errorMessage = error}

        Err error ->
            { model | errorMessage = error }


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
                if model.errorMessage == "" then
                    div [] [ page model ]
                else
                    div [] [text model.errorMessage]

            Edit ->
                editPage model
        ]

editPage : Model -> Html Msg
editPage model = 
    case model.edit of
        Just paper ->            
            div [] 
            [
                div [] [inputDiv "Title: " paper.title InputTitle]
                ,div [] [editPaperLink paper]
                ,div [] [div [class "label"] 
                    [text "Comment: "]
                    , textarea [cols 80, onInput InputComment] [text paper.comment]
                    ]
                ,div [] [div [class "label"] [text "References: "], (editReferences paper.id paper.references)]
                ,div [] 
                [
                    normalFlatButton model.debounce Save "Save"
                    ,normalFlatButton True Cancel "Cancel"
                ]
            ]

        Nothing ->
            div [] [text "Paper not found.  Should not occur."]

editReferences : Int -> List Reference -> Html Msg
editReferences paperId references = 
    div [] 
    [
        div [] [div [] [wideFlatButton True AddReference "Add reference"]]
        ,div [] [div [] (List.map editReference (List.sortBy .index references))]
    ]


editLink : (String -> Msg) -> (String -> Msg) -> Link -> Html Msg
editLink makeMessageText makeMessageLink link =
    div []
    [
        inputDiv "Link text: " link.text makeMessageText,
        urlDiv "Link: " link.link makeMessageLink
    ]

editReference : Reference -> Html Msg
editReference reference = 
    div [] 
    [widerFlatButton True (DeleteReference reference.index) "Delete reference"
      , editLink (InputReferenceText reference.index) (InputReferenceLink reference.index) reference.link
    ]

editPaperLink : Paper -> Html Msg
editPaperLink paper = editLink InputPaperText InputPaperLink paper.paper

inputDivBase : String -> String -> String -> (String -> Msg) -> Html Msg
inputDivBase typeName label currentValue makeMessage =
    div [] [div [class "label"] [text label], input[type_ typeName, value currentValue, onInput makeMessage] []]

inputDiv = inputDivBase "text"
urlDiv = inputDivBase "url"

makeNewTitle : (Maybe Paper) -> String -> Maybe Paper
makeNewTitle maybePaper newTitle =
    case maybePaper of
        Just paper  ->
            Just {paper | title = newTitle}

        Nothing ->
            Nothing
            
makeNewComment : (Maybe Paper) -> String -> Maybe Paper
makeNewComment maybePaper newComment =
    case maybePaper of
        Just paper  ->
            Just {paper | comment = newComment}

        Nothing ->
            Nothing
            
makeNewPaperText: (Maybe Paper) -> String -> Maybe Paper
makeNewPaperText maybePaper newText =
    case maybePaper of
        Just paper  ->
            let
                oldPaper = paper.paper
                newPaper = {oldPaper | text = newText}
            in
                    
            Just {paper | paper = newPaper}

        Nothing ->
            Nothing
             
makeNewPaperLink: (Maybe Paper) -> String -> Maybe Paper
makeNewPaperLink maybePaper newLink =
    case maybePaper of
        Just paper  ->
            let
                oldPaper = paper.paper
                newPaper = {oldPaper | link = newLink}
            in
                    
            Just {paper | paper = newPaper}

        Nothing ->
            Nothing

addReference : (Maybe Paper) -> Maybe Paper
addReference maybePaper = 
    case maybePaper of
        Just paper  ->
            let
                maybeMax = List.maximum (List.map (\ reference -> reference.index) paper.references)
                newIndex = case maybeMax of
                    Just max ->
                        max + 1
                    Nothing ->
                        1
                
                newReference = Reference newIndex (Link "" "")
            in
                Just {paper | references = newReference :: paper.references}

        Nothing ->
            Nothing   

deleteReference : (Maybe Paper) -> Int -> Maybe Paper
deleteReference maybePaper referenceIndex = 
    case maybePaper of
        Just paper  ->
            let
                trim = \ reference -> reference.index /= referenceIndex
                trimmedReferences = List.filter trim  paper.references
                setIndex = \ listIndex reference -> {reference | index = listIndex + 1}
                newReferences = List.indexedMap setIndex trimmedReferences
            in
            Just {paper | references = newReferences}

        Nothing ->
            Nothing   
             
makeNewReference: (Link -> String -> Link) -> (Maybe Paper) -> Int -> String -> Maybe Paper
makeNewReference setFunction maybePaper referenceIndex newText =
    case maybePaper of
        Just paper  ->
            let
                setLink = \ reference -> 
                    if reference.index == referenceIndex then
                        {reference | link = setFunction reference.link newText}
                    else
                        reference

                newReferences = List.map setLink paper.references
            in
                    
            Just {paper | references = newReferences}

        Nothing ->
            Nothing

setLinkText : Link -> String -> Link
setLinkText link text =
    {link | text = text}

setLinkLink : Link -> String -> Link
setLinkLink link text =
    {link | link = text}
    
makeNewReferenceLink = makeNewReference setLinkLink
makeNewReferenceText = makeNewReference setLinkText



--  ----------------------   Login stuff

loginPage : Model -> Html Msg
loginPage model =
    div [] 
    
    [ div [class "password-line"] [ input [ placeholder "Name", onInput Name ] [] ]
    , div [class "password-line"] [ normalFlatButton model.debounce StartLogin "Login"]
    , div [class "password-line"] [ text model.errorMessage ]        
    , div [class "password-line"] [ wideFlatButton True ClearFetch "Clear error" ]
    ]
    
flatButton : String -> Bool -> Msg -> String -> Html Msg
flatButton otherClass enabled click label =
    let
        others = 
            if enabled then
                [class "flat-enabled", onClick click ]        
            else
                [class "flat-disabled"]
    in
            
    div (List.append [class "flat-button", class otherClass] others) [text label]

normalFlatButton = flatButton "normal"
wideFlatButton = flatButton "wide"
widerFlatButton = flatButton "wider"
thinFlatButton = flatButton "thin"

makeLink: Link -> Html msg
makeLink link =
    a [(href link.link), (target "_blank")] [text link.text]


--------------------------------------

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

        displayVotes = \ vote -> div [] [ text (vote.name ++ " "), text (toString vote.votes)]
    in
        tr [ class "entry" ]
            [ td []
                [ div []
                    [ div [ class "submitter" ] [ text paper.submitter ]
                    , normalFlatButton belongsTo (DoEdit paper.id) "Edit"
                    , normalFlatButton (model.debounce && belongsTo) (Close paper.id) "Close" 
                    ]
                ]
            , td []
                ([ (div [] [ h5 [] [ text paper.title ] ])
                , (div [] [makeLink paper.paper])
                , (div [ class "contents" ] [ text paper.comment ])
                ] ++ (List.map (\ ref-> div [] [makeLink ref.link]) (List.sortBy .index paper.references)))
            , td [ class "vote" ]
                [ 
                    thinFlatButton (model.debounce && thisVoterCount > 0) (DecrementVote paper.id) " -"
                    , text " "
                    , text (toString thisVoterCount)
                    , text " "
                    , thinFlatButton (model.debounce && voteLimit model thisVoterCount) (IncrementVote paper.id) "+"
                ]
            , td [] (List.map displayVotes paper.votes)
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
        available = Config.maxVotes - (countVotes model)
    in
        (available > 0) && (Config.maxPerPaper > thisVoterCount)

validateAdd : Model -> Bool
validateAdd model =
    Config.maxPapers > (List.length (List.filter (\ paper -> model.name == paper.submitter) model.papers))            

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
    List.member name (List.map (\ vote -> vote.name) paper.votes)


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
            , div [] [(normalFlatButton (model.debounce && validateAdd model) Add "Add")
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
fetch payload =
    let
        mime =
            "application/json"

        url = Config.backend

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
