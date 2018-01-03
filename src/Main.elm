module Main exposing (main)

import Html exposing (Html, div, text, h1)
import Html.Attributes exposing (class)
import AnimationFrame exposing (times)
import Http exposing (Body, Error, emptyBody, send, request, expectString, expectStringResponse)
import Date
import Set

import Types exposing (..)
import Parse exposing (parsePaperList, parseRules, parseLogin)
import Payload exposing (loginPayload, paperPayload, votePayload, closePayload)
import Wait exposing (waitPage)
import Login exposing (loginPage)
import PaperListing exposing (paperListPage)
import Edit exposing (editPage)

main =
    Html.programWithFlags { init = init, view = view, update = update, subscriptions = subscriptions }

init: String -> ( Model, Cmd Msg )
init target =
    let
        rules = Rules 5 15 5
        model = Model target rules Wait False totalCount "" "" [] Title "" [] Nothing True
    in
            
    ( model, fetchRules model)



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.countDown > 0 then
        times (\time -> Waiting)
    else
        Sub.none

-- view

view : Model -> Html Msg
view model =
    div [ class "outer" ]
        [ div [] [ h1 [] [ text "Cabal Voting System" ] ]
        , case model.page of
            Wait ->
                waitPage model
                
            Login ->
                loginPage model

            List ->
                if model.errorMessage == "" then
                    div [] [ paperListPage model ]
                else
                    div [] [text model.errorMessage]

            Edit ->
                editPage model
        ]


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
-- Waiting and Rules updates

        Waiting ->
            ({model | countDown = model.countDown - 1}, Cmd.none)

        RulesResult (Ok response) ->
            (debounce (updateRules model response), Cmd.none)

        RulesResult (Err error) ->
            (debounce {model | errorMessage = formatError error}, Cmd.none )

--  Login page updates

        Name newName ->
            ( { model | name = newName}, Cmd.none)

        StartLogin ->
            (bounce model, fetchLogin (loginPayload model.name) model)

        UpdateLogin (Ok response) ->
            (updateLogin model response, fetchReload model)

        UpdateLogin (Err error) ->
            (debounce { model | errorMessage = formatError error}, Cmd.none )
-- fetch 

        FetchResult (Ok response) ->
            (debounce (updateModel model response), Cmd.none)

        FetchResult (Err error) ->
            (debounce { model | errorMessage = formatError error}, Cmd.none )

        ClearFetch ->
            ( { model | errorMessage = "" }, Cmd.none )

--  List page updates

        Add ->
            ({model | page = Edit, edit = Just (newPaper model.name)}, Cmd.none)

        Reload ->
            (bounce model, fetchReload model)

        ChangeOrder newOrder ->
            ( { model | order = newOrder }, Cmd.none )

        ChangeVoter newVoter ->
            ( { model | voter = newVoter }, Cmd.none )

        DoEdit id ->
            ({model | page = Edit, edit = getPaper model.papers id}, Cmd.none)

        Close id ->
            (bounce model, fetchClose (closePayload id) model)

        IncrementVote id ->
            (bounce model, fetchVote (votePayload id) model)

        DecrementVote id ->
            (bounce model, fetchUnvote (votePayload id) model)

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
                    (bounce model, fetchSave (paperPayload paper) model)
                Nothing ->
                    ({model | errorMessage = "No paper.  Should not happen"}, Cmd.none)

        Cancel ->
            ({model | page = List, edit = Nothing}, Cmd.none)

newPaper : String -> Paper
newPaper submitter = 
    Paper 0 "" (Link "Paper" "") "" [] (Date.fromTime 0) submitter []

getPaper : List Paper -> Int -> Maybe Paper
getPaper paperList id =
    List.head (List.filter (\ paper -> id == paper.id) paperList)            

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
            Debug.crash "Paper needs to be present" 

makeSetIndex: Int -> (Reference -> Reference)
makeSetIndex referenceIndex =
    \ reference ->
        if (reference.index > referenceIndex) then
            {reference | index = reference.index - 1}
        else
            reference

deleteReference : (Maybe Paper) -> Int -> Maybe Paper
deleteReference maybePaper referenceIndex = 
    case maybePaper of
        Just paper  ->
            let
                trim = \ reference -> reference.index /= referenceIndex
                trimmedReferences = List.filter trim  paper.references
                setIndex = makeSetIndex referenceIndex
                newReferences = List.map setIndex trimmedReferences
            in
            Just {paper | references = newReferences}

        Nothing ->
            Debug.crash "Paper needs to be present" 
             
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
            Debug.crash "Paper needs to be present" 

setLinkText : Link -> String -> Link
setLinkText link text =
    {link | text = text}

setLinkLink : Link -> String -> Link
setLinkLink link text =
    {link | link = text}
    
makeNewReferenceLink = makeNewReference setLinkLink
makeNewReferenceText = makeNewReference setLinkText

getVoters : List Paper -> List String
getVoters paperList = 
    let
        insert : Vote -> (Set.Set String) -> Set.Set String
        insert = \ vote nameSet -> Set.insert vote.name nameSet
        inner:  (List Vote) -> (Set.Set String) -> Set.Set String
        inner = \ voteList nameSet-> List.foldl insert nameSet voteList
        nameSet = List.foldl (\ paper nameSet-> inner paper.votes nameSet) (Set.fromList []) paperList 
    in
        Set.toList nameSet


debounce : Model -> Model
debounce model = 
    {model | debounce = True}

bounce : Model -> Model
bounce model = 
    {model | debounce = False}

updateRules: Model -> String -> Model
updateRules model response =
    case parseRules response of
        Ok rules ->
            {model | rules = rules, countDown = 0, page = Login}

        Err error ->
            {model | errorMessage = error, countDown = 0}

updateLogin : Model -> String -> Model
updateLogin model response =
    case parseLogin response of
        Ok admin ->
            {model | admin = admin.admin}

        Err error ->
            {model | errorMessage = error}

updateModel : Model -> String -> Model
updateModel model response =
    case parsePaperList response of
        Ok paperList ->
            let
                papers = paperList.papers

                sortVoter = 
                    if model.voter == "" then
                        model.name
                    else
                        model.voter
            in
                    
            { model | errorMessage = ""
                , page = List
                , papers = papers
                , voters = getVoters papers
                , voter = sortVoter
            }

        Err error ->
            { model | errorMessage = error }


formatError : Error -> String
formatError error =
    case (Debug.log "error" error) of
        Http.BadUrl url ->
            "Bad URL " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus response ->
            response.body

        Http.BadPayload explain result ->
            "Bad payload" ++ explain


fetchRules = fetch "POST" "rules" True RulesResult emptyBody

fetchLogin = fetch "POST" "login" True UpdateLogin 

fetchReload = fetch "POST" "reload" True FetchResult emptyBody

fetchClose = fetch "POST" "close" True FetchResult

fetchVote = fetch "POST" "vote" True FetchResult

fetchUnvote = fetch "POST" "unvote" True FetchResult

fetchSave = fetch "POST" "save" True FetchResult

fetch : String -> String -> Bool -> (Result Error String -> Msg) -> Body -> Model -> Cmd Msg
fetch method route credential action body model =
    let
        url = model.target ++ "/" ++ route

        req = 
            request
                { method = method
                , headers = []
                , url = url
                , body = body
                , expect = expectString
                , timeout = Nothing
                , withCredentials = credential
                }
    in
        send action req

