module Main exposing (main)

import Html exposing (Html, div, input, button, text, h1, h2, h3, h5, table, thead, tr, th, td, label, 
    select, option, a, textarea)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Date
import Set
import Config
import Parse exposing (Paper, Link, Vote, parse)

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
    , fetchError : String
    , papers : List Paper
    , order : PaperOrder
    , voter : String
    , voters : List String
    , edit : Maybe Paper
    }


init : ( Model, Cmd Msg )
init =
    ( (Model Login "" "" [] Title "" [] Nothing), Cmd.none )



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
    | FetchResult (Result Http.Error ResponseString)
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
            (model, startLogin model.name)

-- fetch 

        FetchResult (Ok response) ->
            updateModel model response

        FetchResult (Err error) ->
            ( { model | fetchError = formatError error }, Cmd.none )

        ClearFetch ->
            ( { model | fetchError = "" }, Cmd.none )

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
            ({model | papers = delete model.papers id}, Cmd.none)

        IncrementVote id ->
            (model, Cmd.none)

        DecrementVote id ->
            (model, Cmd.none)

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
            (model, Cmd.none)

        Cancel ->
            ({model | page = List, edit = Nothing}, Cmd.none)


startLogin : String -> Cmd Msg
startLogin name =
    fetch name

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


updateModel : Model -> ResponseString -> ( Model, Cmd Msg )
updateModel model response =
    let
        result =
            parse response
    in
        case result of
            Ok papers ->
                ( { model | papers = papers, voters = getVoters papers}, Cmd.none )

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
                div [] [inputDiv "Title: " paper.title InputTitle]
                ,div [] [editPaperLink paper]
                ,div [] [div [class "label"] 
                    [text "Comment: "]
                    , textarea [cols 80, onInput InputComment] [text paper.comment]
                    ]
                ,div [] [div [class "label"] [text "References: "], (editReferences paper.id paper.references)]
                ,div [] 
                [
                    normalFlatButton True Save "Save"
                    ,normalFlatButton True Cancel "Cancel"
                ]
            ]

        Nothing ->
            div [] [text "Paper not found.  Should not occur."]

editReferences : Int -> List Link -> Html Msg
editReferences paperId references = 
    div [] 
    [
        div [] [div [] [wideFlatButton True AddReference "Add reference"]]
        ,div [] [div [] (List.map editLink (List.sortBy .index references))]
    ]


editLinkBase : (String -> Msg) -> (String -> Msg) -> Link -> Html Msg
editLinkBase makeMessageText makeMessageLink link =
    div []
    [
        inputDiv "Link text: " link.text makeMessageText,
        urlDiv "Link: " link.link makeMessageLink
    ]

editLink : Link -> Html Msg
editLink link = 
    div [] 
    [wideFlatButton True (DeleteReference link.index) "Delete reference"
      , editLinkBase (InputReferenceText link.index) (InputReferenceLink link.index) link
    ]

editPaperLink : Paper -> Html Msg
editPaperLink paper = editLinkBase InputPaperText InputPaperLink paper.paper

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
                newMax = case maybeMax of
                    Just max ->
                        max + 1
                    Nothing ->
                        1
                
                newReference = Link newMax "" ""
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
             
makeNewReferenceText: (Maybe Paper) -> Int -> String -> Maybe Paper
makeNewReferenceText maybePaper referenceIndex newText =
    case maybePaper of
        Just paper  ->
            let
                setText = \ link -> 
                    if link.index == referenceIndex then
                        {link | text = newText}
                    else
                        link

                newReferences = List.map setText paper.references
            in
                    
            Just {paper | references = newReferences}

        Nothing ->
            Nothing

makeNewReferenceLink: (Maybe Paper) -> Int -> String -> Maybe Paper
makeNewReferenceLink maybePaper referenceIndex newLink =
    case maybePaper of
        Just paper  ->
            let
                setText = \ link -> 
                    if link.index == referenceIndex then
                        {link | link = newLink}
                    else
                        link
 
                newReferences = List.map setText paper.references
            in
                    
            Just {paper | references = newReferences}

        Nothing ->
            Nothing




--  ----------------------   Login stuff

loginPage : Model -> Html Msg
loginPage model =
    div [] 
    
    [ div [class "password-line"] [ input [ placeholder "Name", onInput Name ] [] ]
    , div [class "password-line"] [ normalFlatButton True StartLogin "Login"]
    , div [class "password-line"] [ text model.fetchError ]        
    , div [class "password-line"] [ wideFlatButton True ClearFetch "Clear error" ]
    ]
    
flatButton : String -> Bool -> Msg -> String -> Html Msg
flatButton otherClass enabled click label =
    let
        enableClass = if enabled then
            class "flat-enabled"
        else
            class "flat-disabled"
    in
            
    div [class "flat-button", class otherClass, enableClass, onClick click ] [text label]

normalFlatButton = flatButton "normal"
wideFlatButton = flatButton "wide"
thinFlatButton = flatButton "thin"

makeLink: Link -> Html msg
makeLink link =
    a [(href link.link), (target "_blank")] [text link.text]

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
                    , normalFlatButton belongsTo (Close paper.id) "Close" 
                    ]
                ]
            , td []
                ([ (div [] [ h5 [] [ text paper.title ] ])
                , (div [] [makeLink paper.paper])
                , (div [ class "contents" ] [ text paper.comment ])
                ] ++ (List.map (\ ref-> div [] [makeLink ref]) (List.sortBy .index paper.references)))
            , td [ class "vote" ]
                [ 
                    thinFlatButton (thisVoterCount > 0) (DecrementVote paper.id) " -"
                    , text " "
                    , text (toString thisVoterCount)
                    , text " "
                    , thinFlatButton (voteLimit model thisVoterCount) (IncrementVote paper.id) "+"
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
            , div [] [(normalFlatButton True Add "Add")
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
fetch name =
    let
        mime =
            "application/json"

        url =
            "https://127.0.0.1:8040"

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
