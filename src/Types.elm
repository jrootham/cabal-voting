module Types exposing (..)

import Date
import Http

totalCount = 30 * 60

type alias Model =
    { target : String
    , rules : Rules
    , page : Page
    , admin : Bool
    , countDown : Int
    , name : String
    , errorMessage : String
    , papers : List Paper
    , order : PaperOrder
    , voter : String
    , voters : List String
    , edit : Maybe Paper
    , debounce : Bool
    }

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


type Page = Wait | Login | List | Edit


type Msg
    = Waiting
    | RulesResult (Result Http.Error String)
    | Name String
    | StartLogin
    | UpdateLogin (Result Http.Error String)
    | Add
    | Reload
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

type alias PaperList = {papers: List Paper}

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

type alias LoginData = 
    { cookie: String
    , admin: Bool
    }