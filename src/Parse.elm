module Parse exposing (Paper, Reference, Link, Vote, ErrorAndPaperList, parse)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Result
import Date

type alias ErrorAndPaperList =
    { error: String
      , paperList : List Paper
    }

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

parse : String -> Result String ErrorAndPaperList
parse responseString =
    decodeString decodeErrorAndPaperList responseString

decodeErrorAndPaperList : Decoder ErrorAndPaperList
decodeErrorAndPaperList =
    decode ErrorAndPaperList
        |> required "error" string
        |> required "paper_list" (list decodePaper)

decodePaper : Decoder Paper
decodePaper =
    decode Paper
        |> required "paper_id" int
        |> required "title" string
        |> required "paper" linkDecoder
        |> required "paper_comment" string
        |> required "references" (list referenceDecoder)
        |> required "created_at" dateDecoder
        |> required "submitter" string
        |> required "votes" (list voteDecoder)

referenceDecoder : Decoder Reference
referenceDecoder =
  decode Reference
    |> required "reference_index" int
    |> required "link" linkDecoder

linkDecoder : Decoder Link
linkDecoder =
    decode Link
        |> required "text" string
        |> required "link" string

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


voteDecoder : Decoder Vote
voteDecoder =
    decode Vote
        |> required "name" string
        |> required "votes" int
