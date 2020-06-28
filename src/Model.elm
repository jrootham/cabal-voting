module Model exposing ( Model, User, Data, Rules, Paper, Reference, Vote, Response
  , PaperOrder(..), Page(..), Error(..), Msg(..)
  , initialModel, loginDecoder, responseDecoder, paperPayload, closePayload, votePayload
  , newPaper, newReference
  , getMaxPapers, getMaxVotes, getMaxPerPaper
  , getUser, setUser, getPage, setPage, getOrder, setOrder, getSortByVoter, setSortByVoter
  , getError, setError, clearError, getDebounce, setDebounce
  , getEditingPaper, setEditingPaper, clearEditingPaper
  , getPaperList, setPaperList, getVoterList, setData
  )

import List as L
import Json.Decode as JD
import Json.Decode.Pipeline as JP
import Json.Encode as JE
import Http
import Time

type Msg
  = Login (Result Http.Error (Maybe User))
  | Load (Result Http.Error Response)
  | NewPaper Time.Posix
  | ClearError
  | ChangeOrder PaperOrder
  | ChangeVoter User
  | Reload
  | DoClose Time.Posix
  | Close Paper
  | IncrementVote Paper
  | DecrementVote Paper
  | Add
  | DoEdit Paper
  | Cancel
  | InputTitle String
  | InputComment String
  | Save
  | AddReference
  | DeleteReference Reference
  | InputReferenceText Reference String
  | InputReferenceLink Reference String
  | InputPaperLink String


type alias Model =
  { currentUser : Maybe User
  , page : Page
  , order : PaperOrder
  , sortByVoter : User
  , error : Maybe Error
  , debounce : Bool
  , editingPaper : Maybe Paper
  , data : Data
  }

-- Initialize 

initialModel =
  let
    rules = Rules 5 15 5
    data = Data rules []
  in
  Model Nothing Display Title "" Nothing True Nothing data 


type alias User = String

type alias Data =
  { rules : Rules
  , paperList : List Paper
  }

type alias Response =
  { error : Maybe String
  , data : Maybe Data
  }

type alias Rules =
  { maxPapers : Int
  , maxVotes : Int
  , maxPerPaper : Int
  }

type alias Paper =
  { id : Int
  , title : String
  , link : String
  , comment : String
  , referenceList : List Reference
  , createdAt : Time.Posix
--  , closedAt : Maybe Time.Posix
  , submitter : User
  , voteList : List Vote
  }

newPaper : User -> Time.Posix -> Paper
newPaper user now =
  Paper 0 "" "" "" [] now user [] 

type PaperOrder
  = Title
  | Earliest
  | Latest
  | LeastVotes
  | MostVotes
  | Submitter
  | Mine
  | Voter 

type alias Reference =
  { index : Int
  , text : String
  , link : String
  }

newReference : Paper -> Reference
newReference paper =
  let
    maxScan = L.maximum (L.map .index paper.referenceList)
  in
    case maxScan of
      Just maxIndex ->
        Reference (maxIndex + 1) "" ""

      Nothing ->
        Reference 1 "" ""

type alias Vote =
  { user : User
  , votes : Int
  }

type Page
  = Display
  | Edit

type Error 
  = HttpError Http.Error
  | LocalError String
  | RemoteError String

--  User access

getUser : Model -> Maybe User
getUser model =
  model.currentUser

setUser : Maybe User -> Model -> Model
setUser user model =
  {model | currentUser = user}

-- State access functions

getPage : Model -> Page
getPage model =
  model.page

setPage : Page -> Model -> Model
setPage page model =
  {model | page = page}

getOrder : Model -> PaperOrder
getOrder model =
  model.order

setOrder : PaperOrder -> Model -> Model
setOrder order model =
    {model | order = order}

getSortByVoter : Model -> User
getSortByVoter model =
  model.sortByVoter

setSortByVoter : User -> Model -> Model
setSortByVoter user model=
  {model | sortByVoter = user}

getDebounce : Model -> Bool
getDebounce model =
  model.debounce

setDebounce : Bool -> Model -> Model
setDebounce debounce model =
  {model | debounce = debounce}

getError : Model -> Maybe Error
getError model =
  model.error

setError : Error -> Model -> Model
setError error model =
  {model | error = Just error}

clearError : Model -> Model
clearError model =
  {model | error = Nothing}  

getEditingPaper : Model -> Maybe Paper
getEditingPaper model =
  model.editingPaper

setEditingPaper : Paper -> Model -> Model
setEditingPaper paper model =
  {model | editingPaper = Just paper}

clearEditingPaper : Model -> Model
clearEditingPaper model =
  {model | editingPaper = Nothing}

-- Rules access functions

getMaxPapers: Model -> Int
getMaxPapers model =
  model.data.rules.maxPapers

getMaxVotes: Model -> Int
getMaxVotes model =
  model.data.rules.maxVotes

getMaxPerPaper: Model -> Int
getMaxPerPaper model =
  model.data.rules.maxPerPaper

-- Data access functions

setData : Data -> Model -> Model
setData data model =
  {model | data = data}
  
getPaperList : Model -> List Paper
getPaperList model =
  model.data.paperList

setPaperList : List Paper -> Model -> Model
setPaperList paperList model =
  let
    data = model.data
  in
    {model | data = {data | paperList = paperList}}

getVoterList : Model -> List User
getVoterList model =
  L.sort (L.foldl (uniqueVoters) [] (getPaperList model))

uniqueVoters : Paper -> List User -> List User
uniqueVoters paper voterList =
  L.foldl (getNewVoter) voterList paper.voteList

getNewVoter : Vote -> List User -> List User
getNewVoter vote userList =
  let
    user = vote.user
  in
    if L.member user userList
    then
      userList
    else 
      user :: userList


-- Decode data from server

-- Login

loginDecoder : JD.Decoder (Maybe User)
loginDecoder = JD.nullable JD.string

-- Response

responseDecoder : JD.Decoder Response
responseDecoder =
  JD.succeed Response
    |> JP.required "error" (JD.nullable JD.string)
    |> JP.required "data" (JD.nullable dataDecoder)

dataDecoder : JD.Decoder Data
dataDecoder = 
  JD.succeed Data
    |> JP.requiredAt ["data", "rules"] rulesDecoder
    |> JP.requiredAt ["data", "paper_list"] (JD.list paperDecoder)

rulesDecoder : JD.Decoder Rules
rulesDecoder =
  JD.succeed Rules
    |> JP.required "max_papers" JD.int
    |> JP.required "max_votes" JD.int
    |> JP.required "max_votes_per_paper" JD.int

paperDecoder : JD.Decoder Paper
paperDecoder =
  JD.succeed Paper
    |> JP.required "paper_id" JD.int
    |> JP.required "title" JD.string
    |> JP.required "link" JD.string
    |> JP.required "paper_comment" JD.string
    |> JP.required "reference_list" (JD.list referenceDecoder)
    |> JP.required "created_at" timeDecoder
--    |> JP.required "closed_at" (JD.nullable timeDecoder)
    |> JP.required "submitter" JD.string
    |> JP.required "vote_list" (JD.list voteDecoder)


referenceDecoder : JD.Decoder Reference
referenceDecoder =
  JD.succeed Reference
    |> JP.required "reference_index" JD.int
    |> JP.required "link_text" JD.string
    |> JP.required "link" JD.string


timeDecoder : JD.Decoder Time.Posix
timeDecoder =
  JD.int |> JD.andThen int2Time

int2Time : Int -> JD.Decoder Time.Posix
int2Time  time = 
  JD.succeed (Time.millisToPosix (1000 * time))

voteDecoder : JD.Decoder Vote
voteDecoder =
  JD.succeed Vote
    |> JP.required "name" JD.string
    |> JP.required "votes" JD.int

-- Payload definitions

mime = "application/x-www-form-urlencoded"

-- Sending translation for updating Paper

paperPayload : Paper -> Http.Body
paperPayload paper =
    Http.stringBody mime ("paper=" ++ (JE.encode 0 (paperContents paper)))

paperContents : Paper -> JE.Value
paperContents paper =
  JE.object
    [ ( "id", JE.int paper.id )
    , ( "title", JE.string paper.title )
    , ( "link", JE.string paper.link )
    , ( "comment", JE.string paper.comment )
    , ( "reference_list", referenceListContents paper.referenceList )
    , ( "created_at", JE.int ((Time.posixToMillis paper.createdAt) // 1000))
--    , ( "submitter", JE.string paper.submitter )  Get submitter from signon id
    , ( "vote_list", voteListContents paper.voteList )
    ]

referenceListContents : List Reference -> JE.Value
referenceListContents referenceList =
  JE.list referenceContents referenceList

referenceContents : Reference -> JE.Value
referenceContents reference =
    JE.object 
      [ ( "index", JE.int reference.index )
      , ( "link_text", JE.string reference.text )
      , ( "link", JE.string reference.link ) 
      ]

voteListContents : List Vote -> JE.Value
voteListContents voteList =
  JE.list voteContents voteList

voteContents : Vote -> JE.Value
voteContents vote =
  JE.object
    [ ("user", JE.string vote.user )
    , ("votes", JE.int vote.votes )
    ]

--  Sending translation for close

closePayload : Paper -> Time.Posix -> Http.Body
closePayload paper time =
  let 
    paperIdString = String.fromInt paper.id
    timeString = String.fromInt ((Time.posixToMillis time) // 1000) 
  in
    Http.stringBody mime ("paper-id=" ++ paperIdString ++ "&time=" ++ timeString)


--  Sending translation for voting

votePayload : Paper -> Http.Body
votePayload paper =
  Http.stringBody mime ("paper-id=" ++ (String.fromInt paper.id))


