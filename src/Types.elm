module Types exposing (..)

import Date
import Http

totalCount = 30 * 60

type alias PaperModel =
    { paperList : List Paper
    , order : PaperOrder
    , voter : String
    , voterList : List String
    , edit : Maybe Paper
    } 

type alias UserModel =
    { userList : Maybe (List User) 
    , user : Maybe User
    }

type alias Model =
    { target : String
    , rules : Rules
    , page : Page
    , countDown : Int
    , currentUser : Maybe User
    , errorMessage : String
    , debounce : Bool
    , paperModel : PaperModel
    , userModel : UserModel
    , openPaperList : Maybe (List OpenPaper)
    , closedPaperList : Maybe (List ClosedPaper)
    , editRules : Maybe RulesBuffer
    }

initialModel target =
    let
        rules = Rules 5 15 5
        paperModel = PaperModel [] Title "" [] Nothing
        userModel = UserModel Nothing Nothing
    in
        Model target rules Wait totalCount Nothing "" True paperModel userModel Nothing Nothing Nothing
 
getPaperList : Model -> List Paper
getPaperList model =
    model.paperModel.paperList

setPaperList : List Paper -> Model -> Model
setPaperList paperList model =
    let
        temp = model.paperModel
        paperModel = {temp | paperList = paperList}
    in
    {model | paperModel = paperModel}

getPaperOrder : Model -> PaperOrder
getPaperOrder model =
    model.paperModel.order

setPaperOrder : PaperOrder -> Model -> Model
setPaperOrder order model =
    let
        temp = model.paperModel
        paperModel = {temp | order = order}
    in
    {model | paperModel = paperModel}

getVoter : Model -> String
getVoter model =
    model.paperModel.voter

setVoter : String -> Model -> Model
setVoter voter model =
    let
        temp = model.paperModel
        paperModel = {temp | voter = voter}
    in
    {model | paperModel = paperModel}

getVoterList : Model -> List String
getVoterList model =
    model.paperModel.voterList

setVoterList : List String -> Model -> Model
setVoterList voterList model =
    let
        temp = model.paperModel
        paperModel = {temp | voterList = voterList}
    in
        {model | paperModel = paperModel}

getEdit : Model -> Maybe Paper
getEdit model =
    model.paperModel.edit

setEdit : Maybe Paper -> Model -> Model
setEdit edit model =
    let
        temp = model.paperModel
        paperModel = {temp | edit = edit}
    in
    {model | paperModel = paperModel}

getUserList : Model -> Maybe (List User)
getUserList model =
    model.userModel.userList

setUserList : Maybe (List User) -> Model -> Model
setUserList userList model =
    let
        temp = model.userModel
        userModel = {temp | userList = userList}
    in
    {model | userModel = userModel}

getEditUser : Model -> Maybe User
getEditUser model =
    model.userModel.user

setEditUser : Maybe User -> Model -> Model
setEditUser user model =
    let
        temp = model.userModel
        userModel = {temp | user = user}
    in
        {model | userModel = userModel}


type alias Rules =
    { maxPapers: Int
    , maxVotes: Int
    , maxPerPaper: Int
    }

type alias RulesBuffer =
    { maxPapers: String
    , maxVotes: String
    , maxPerPaper: String
    }

makeRulesBuffer: Rules -> RulesBuffer
makeRulesBuffer rules =
    RulesBuffer (toString rules.maxPapers) (toString rules.maxVotes) (toString rules.maxPerPaper)

makeMaxPapers: Rules -> RulesBuffer -> Result String Rules
makeMaxPapers rules rulesBuffer =
    case String.toInt rulesBuffer.maxPapers of
        Ok maxPapers ->
            Ok {rules | maxPapers = maxPapers}

        Err error ->
            Err error

makeMaxVotes: Result String Rules -> RulesBuffer -> Result String Rules
makeMaxVotes result rulesBuffer =
    case result of
        Ok rules ->
            case String.toInt rulesBuffer.maxVotes of
                Ok maxVotes ->
                    Ok {rules | maxVotes = maxVotes}

                Err error ->
                    Err error

        Err error ->
            Err error

makeMaxPerPaper: Result String Rules -> RulesBuffer -> Result String Rules
makeMaxPerPaper result rulesBuffer =
    case result of
        Ok rules ->
            case String.toInt rulesBuffer.maxPerPaper of
                Ok maxPerPaper ->
                    Ok {rules | maxPerPaper = maxPerPaper}

                Err error ->
                    Err error

        Err error ->
            Err error

makeRules: Maybe RulesBuffer -> Result String Rules
makeRules buffer =
    case buffer of
        Just rulesBuffer ->
            let
                result0 = makeMaxPapers (Rules 0 0 0) rulesBuffer
                result1 = makeMaxVotes result0 rulesBuffer
                result = makeMaxPerPaper result1 rulesBuffer
            in
                case result of
                    Ok rules ->
                        if rules.maxVotes >= rules.maxPerPaper then
                            Ok rules
                        else 
                            Err "Max per paper cannot be greater than max votes."

                    Err error ->
                        Err error

        Nothing ->
            Err "No rules buffer.  Should not happen"

setEditMaxPapers: Model -> String -> Model
setEditMaxPapers model maxPapers =
    case model.editRules of
        Just rules ->
            let
                temp = {rules | maxPapers = maxPapers} 
            in
                {model | editRules = Just temp}

        Nothing ->
            {model | errorMessage = "No editRules.  Should not happen."}

setEditMaxVotes: Model -> String -> Model
setEditMaxVotes model maxVotes =
    case model.editRules of
        Just rules ->
            let
                temp = {rules | maxVotes = maxVotes} 
            in
                {model | editRules = Just temp}
                
        Nothing ->
            {model | errorMessage = "No editRules.  Should not happen."}

setEditMaxPerPaper: Model -> String -> Model
setEditMaxPerPaper model maxPerPaper =
    case model.editRules of
        Just rules ->
            let
                temp = {rules | maxPerPaper = maxPerPaper} 
            in
                {model | editRules = Just temp}
                
        Nothing ->
            {model | errorMessage = "No editRules.  Should not happen."}

getMaxPapers: Model -> Int
getMaxPapers model =
    model.rules.maxPapers

getMaxPerPaper: Model -> Int
getMaxPerPaper model =
    model.rules.maxPerPaper

getMaxVotes: Model -> Int
getMaxVotes model =
    model.rules.maxVotes

type PaperOrder
    = Title
    | Earliest
    | Latest
    | LeastVotes
    | MostVotes
    | Submitter
    | Mine
    | Voter

type Page = Wait | Login | List | Edit | Users | UserPage | OpenListPage | ClosedListPage | EditRulesPage

type Msg
    = Waiting
    | RulesResult (Result Http.Error String)
    | Name String
    | StartLogin
    | Guest
    | UpdateLogin (Result Http.Error String)
    | Add
    | Reload
    | ChangeOrder PaperOrder
    | ChangeVoter String
    | DecrementVote Int
    | IncrementVote Int
    | FetchResult (Result Http.Error String)
    | ClearError
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
    | LoadUsers 
    | ListUsers (Result Http.Error String)
    | EditUser User
    | UserName String
    | UserAdmin Bool
    | UserValid Bool
    | UpdateUser
    | CloseUser
    | ShutUserList
    | OpenList
    | ListOpen (Result Http.Error String)
    | AdminClose Int
    | ShutOpenList
    | ClosedList
    | ListClosed (Result Http.Error String)
    | AdminOpen Int
    | ShutClosedList
    | ShowRules
    | EditRules (Result Http.Error String)
    | MaxPapers String
    | MaxVotes String
    | MaxPerPaper String
    | SaveRules
    | ShutRules

type alias PaperList = {paperList: List Paper}

type alias Paper =
    { id : Int
    , title : String
    , paper : Link
    , comment : String
    , references : List Reference
    , createdAt : Date.Date
    , submitter : String
    , votes : List Vote
    }

type alias Reference =
    { index : Int
      , link : Link
    }
type alias Link =
    { text: String
    , link: String
    }   

type alias Vote =
    { name: String
    , votes : Int
    }

type alias Admin = {admin: Bool}

type alias LoginData = {admin: Bool}

type alias User =
    { id : Int
    , name : String
    , valid : Bool
    , admin : Bool
    }

newUser : User
newUser = User 0 "" True False

newCurrentUser : String -> User
newCurrentUser name =
    User 0 name True False

type alias UserList = {userList : List User}

type alias ClosedPaper =
    { id : Int
    , closedAt : Date.Date
    , title : String
    , comment : String
    }

type alias ClosedPaperList = {paperList : List ClosedPaper}

type alias OpenPaper =
    { id : Int
    , title : String
    , comment : String
    , totalVotes : Int
    }

type alias OpenPaperList = {paperList : List OpenPaper}

    