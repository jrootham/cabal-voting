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
    }

initialModel target =
    let
        rules = Rules 5 15 5
        paperModel = PaperModel [] Title "" [] Nothing
        userModel = UserModel Nothing Nothing
    in
    Model target rules Wait totalCount Nothing "" True paperModel userModel
 
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

type Page = Wait | Login | List | Edit | Users | UserPage

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
    | CloseList
    | OpenList
    | UpdateRules

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
