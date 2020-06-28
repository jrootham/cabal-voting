module Paper exposing (Paper, PaperOrder(..), Reference, Link, Vote)

import Time
import User as U

type alias Paper =
    { id : Int
    , title : String
    , paper : Link
    , comment : String
    , references : List Reference
    , createdAt : Time.Posix
    , closedAt : Maybe(Time.Posix)
    , submitter : User
    , votes : List Vote
    }

type PaperOrder
    = Title
    | Earliest
    | Latest
    | LeastVotes
    | MostVotes
    | Submitter
    | Mine
    | Voter U.UserId

type alias Reference =
    { index : Int
    , link : Link
    }


type alias Link =
    { text : String
    , link : String
    }


type alias Vote =
    { user : U.UserId
    , votes : Int
    }

