module Main exposing (main)

import Html exposing (Html, div, text, h1)
import Html.Attributes exposing (class)
import AnimationFrame exposing (times)
import Http exposing (Body, Error, emptyBody, send, request, expectString, expectStringResponse)
import Date
import Set

import Types exposing (..)
import Common exposing (normalFlatButton)
import Parse exposing (parsePaperList, parseRules, parseLogin, parseUserList)
import Payload exposing (loginPayload, paperPayload, votePayload, closePayload, userPayload)
import Wait exposing (waitPage)
import Login exposing (loginPage)
import PaperListing exposing (paperListPage)
import Edit exposing (editPage)
import User exposing (userPage, editUser)

main =
    Html.programWithFlags { init = init, view = view, update = update, subscriptions = subscriptions }

init: String -> ( Model, Cmd Msg )
init target =
    let
        model = initialModel target     
    in
        (model, fetchRules model)


-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.countDown > 0 then
        times (\ time -> Waiting)
    else
        Sub.none

-- view

view : Model -> Html Msg
view model =
    div [ class "outer" ]
        [ div [] [ h1 [] [ text "Cabal Voting System" ] ]
        , case model.page of
            Wait ->
                ifError waitPage model
                
            Login ->
                loginPage model

            List ->
                ifError paperListPage model

            Edit ->
                ifError editPage model

            Users ->
                ifError userPage model

            UserPage ->
                ifError editUser model
        ]


ifError : (Model -> Html Msg) -> Model -> Html Msg
ifError page model =
    if model.errorMessage == "" then
        page model
    else
        div []  [ div [] [text model.errorMessage]
                , div [] [normalFlatButton True ClearError "Clear Error"]
                ]


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
-- Waiting and Rules updates

        Waiting ->
            ({model | countDown = model.countDown - 1}, Cmd.none)

        RulesResult (Ok response) ->
            (debounce (Debug.log "starting" (updateRules model response)), Cmd.none)

        RulesResult (Err error) ->
            (debounce {model | errorMessage = formatError error}, Cmd.none )

--  Login page updates

        Name newName ->
            ({model | currentUser = Just (newCurrentUser newName)}, Cmd.none)

        StartLogin ->
            case model.currentUser of
                Just user ->
                    (bounce model, fetchLogin (loginPayload user.name) model)

                Nothing ->
                    ({model | errorMessage = "No name entered"} , Cmd.none)

        Guest ->
            (bounce {model | currentUser = Nothing}, fetchReload model)

        UpdateLogin (Ok response) ->
            (updateLogin model response, fetchReload model)

        UpdateLogin (Err error) ->
            (debounce { model | errorMessage = formatError error}, Cmd.none )
-- fetch 

        FetchResult (Ok response) ->
            (debounce (updateModel model response), Cmd.none)

        FetchResult (Err error) ->
            (debounce { model | errorMessage = formatError error}, Cmd.none )

        ClearError ->
            ( { model | errorMessage = "" }, Cmd.none )

--  List page updates

        Add ->
            case model.currentUser of
                Just user ->
                    let
                        temp = setEdit (Just (newPaper user.name)) model
                    in
                            
                    ({temp | page = Edit}, Cmd.none)

                Nothing ->
                    ({model | errorMessage = "No user.  Should not happen"}, Cmd.none)

        Reload ->
            (bounce model, fetchReload model)

        ChangeOrder newOrder ->
            (setPaperOrder newOrder model, Cmd.none )

        ChangeVoter newVoter ->
            (setVoter newVoter model, Cmd.none )

        DoEdit id ->
            let
                temp = setEdit (getPaper (getPaperList model) id) model
            in
                ({temp | page = Edit}, Cmd.none)

        Close id ->
            (bounce model, fetchClose (closePayload id) model)

        IncrementVote id ->
            (bounce model, fetchVote (votePayload id) model)

        DecrementVote id ->
            (bounce model, fetchUnvote (votePayload id) model)

--  Edit page updates

        InputTitle newTitle ->
            (setEdit (makeNewTitle (getEdit model) newTitle) model, Cmd.none)
        
        InputPaperText newText ->
            (setEdit (makeNewPaperText (getEdit model) newText) model, Cmd.none)
        
        InputPaperLink newLink ->
            (setEdit (makeNewPaperLink (getEdit model) newLink) model, Cmd.none)
        
        InputComment newComment ->
            (setEdit (makeNewComment (getEdit model) newComment) model, Cmd.none)
        
        AddReference ->
            (setEdit (addReference (getEdit model)) model, Cmd.none)
        
        DeleteReference referenceIndex ->
            (setEdit (deleteReference (getEdit model) referenceIndex) model, Cmd.none)
        
        InputReferenceText referenceIndex newText ->
            (setEdit (makeNewReferenceText (getEdit model) referenceIndex newText) model, Cmd.none)
        
        InputReferenceLink referenceIndex newLink ->
            (setEdit (makeNewReferenceLink (getEdit model) referenceIndex newLink) model, Cmd.none)
        
        Save ->
            case getEdit model of
                Just paper ->
                    (bounce model, fetchSave (paperPayload paper) model)
                Nothing ->
                    ({model | errorMessage = "No paper.  Should not happen"}, Cmd.none)

        Cancel ->
            (setEdit Nothing {model | page = List}, Cmd.none)

        LoadUsers ->
            (bounce model, fetchUsers model)

        ListUsers (Ok response) ->
            (debounce (setEditUser Nothing (putUserList model response)), Cmd.none)

        ListUsers (Err error) ->
            (debounce { model | errorMessage = formatError error}, Cmd.none )

        EditUser user ->
            (setEditUser (Just user) {model | page = UserPage}, Cmd.none)   

        UserName name ->
            (updateUserField updateEditUserName model name, Cmd.none)

        UserAdmin admin ->
            (updateUserField updateUserAdmin model admin, Cmd.none)

        UserValid valid ->
            (updateUserField updateUserValid model valid, Cmd.none)

        UpdateUser ->
            case getEditUser model of
                Just user ->
                    (bounce model, fetchUpdateUser (userPayload user) model)

                Nothing ->
                    ({model | errorMessage = "No user.  Should not happen"}, Cmd.none)

        CloseUser ->
            (setEditUser Nothing {model | page = Users}, Cmd.none)

        ShutUserList ->
            (setUserList Nothing {model | page = List}, Cmd.none)

        CloseList ->
            (model, Cmd.none)       

        OpenList ->
            (model, Cmd.none)       

        UpdateRules ->
            (model, Cmd.none)       


updateUserField : (Model -> User -> a -> Model) -> Model -> a -> Model
updateUserField update model value =
    case getEditUser model of
        Just user ->
            update model user value

        Nothing ->
            {model | errorMessage = "No user.  Should not happen"}

updateEditUserName : Model -> User -> String -> Model
updateEditUserName model user name =
    setEditUser (Just {user | name = name}) model

updateUserAdmin : Model -> User -> Bool -> Model
updateUserAdmin model user admin =
    setEditUser (Just {user | admin = admin}) model
    
updateUserValid : Model -> User -> Bool -> Model
updateUserValid model user valid =
    setEditUser (Just {user | valid = valid}) model
    

putUserList : Model -> String -> Model
putUserList model response =
    case parseUserList response of
        Ok userList ->
            let
                temp = setUserList (Just userList.userList) model 
            in
                    
            {temp | page = Users}

        Err error ->
            {model | errorMessage = error}

newPaper : String -> Paper
newPaper submitter = 
    Paper 0 "" (Link "Paper" "") "" [] (Date.fromTime 0) submitter []

getPaper : List Paper -> Int -> Maybe Paper
getPaper paperList id =
    List.head (List.filter (\ paper -> id == paper.id) paperList)            

makeNewTitle : Maybe Paper -> String -> Maybe Paper
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
            case model.currentUser of
                Just user ->
                    let
                        newUser = {user | admin = admin.admin}                            
                    in
                        {model | currentUser = Just newUser}

                Nothing ->
                    {model | errorMessage = "No user.  Should not happen"}
                            
        Err error ->
            {model | errorMessage = error}

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

updateModel : Model -> String -> Model
updateModel model response =
    case parsePaperList response of
        Ok paperInput ->
            let
                paperList = paperInput.paperList
                
                voterList = getVoters paperList

                voter = getVoter model

                sortVoter = 
                    if voter == "" then

                        case model.currentUser of
                            Just user ->
                                user.name

                            Nothing ->
                                case List.minimum voterList of
                                    Just voter ->
                                        voter

                                    Nothing ->
                                        ""
                    else
                        voter

                temp = setVoterList voterList (setVoter sortVoter (setPaperList paperList model))

            in                
                {temp | errorMessage = "", page = List}

        Err error ->
            { model | errorMessage = error }


formatError : Error -> String
formatError error =
    case error of
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

fetchUsers = fetch "POST" "userList" True ListUsers emptyBody

fetchUpdateUser = fetch "POST" "updateUser" True ListUsers

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

