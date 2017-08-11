module Parse exposing (parse, NameAndPaperList, Paper)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Result
import Date
import Debug


type alias NameAndPaperList =
    {name : String
     , papers : List Paper
    }

type alias NameAndRawPaperList =
    {name : String
     , papers : List RawPaper
    }


type alias Paper =
    { title : String
    , body : String
    , createdAt : Date.Date
    , submitter : String
    , votes : List String
    }

type alias RawPaper =
    { title : String
    , body : String
    , createdAt : Date.Date
    , submitter : String
    , votes : List String
    }



-- Hang onto this because voting may change


type alias Votes =
    { user : String
    , votes : Int
    }

translateNameAndRawPaperList : NameAndRawPaperList -> NameAndPaperList
translateNameAndRawPaperList raw = 
    NameAndPaperList raw.name (List.map translateRawPaper raw.papers)

translateRawPaper : RawPaper-> Paper
translateRawPaper raw = 
    Paper raw.title raw.body raw.createdAt raw.submitter raw.votes


decodeRawPaper : Decoder RawPaper
decodeRawPaper =
    decode RawPaper
        |> required "title" string
        |> required "bodyHTML" string
        |> required "createdAt" dateDecoder
        |> required "author" (field "login" string)
        |> required "reactions" voteDecoder


dateDecoder : Decoder Date.Date
dateDecoder =
    string
        |> andThen
            (\str ->
                case Date.fromString str of
                    Err err ->
                        fail err

                    Ok date ->
                        succeed date
            )


voteDecoder : Decoder (List String)
voteDecoder =
    at [ "nodes" ] (list (at [ "user", "login" ] string))


decodeNameAndRawPaperList : Decoder NameAndRawPaperList
decodeNameAndRawPaperList =
    decode NameAndPaperList
        |> requiredAt [ "viewer", "login"] string 
        |> requiredAt [ "repository", "issues", "nodes" ] (list decodeRawPaper)



parse : String -> Result String NameAndPaperList
parse response =
    let
        raw = rawParse response
        foo = Debug.log "raw" raw
    in
        case raw of
            Err err ->
                Err (Debug.log "err" err)

            Ok data ->
                Ok (Debug.log "data" data)

                --succeed (translateNameAndRawPaperList data)
rawParse : String -> Result String NameAndRawPaperList
rawParse response =
    decodeString (at [ "data" ] decodeNameAndRawPaperList) response

