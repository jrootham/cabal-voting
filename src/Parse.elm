module Parse exposing (parsePaperList, parseRules, parseLogin)

import Json.Decode exposing (Decoder, decodeString, int, string, bool, list, succeed, fail, andThen)
import Json.Decode.Pipeline exposing (decode, required)
import Http exposing (Response)
import Result
import Date

import Types exposing (..)

parseRules : String -> Result String Rules
parseRules responseString =
    decodeString decodeRules responseString

decodeRules: Decoder Rules
decodeRules =
    decode Rules
        |> required "max_papers" int
        |> required "max_votes" int
        |> required "max_votes_per_paper" int

parseLogin : String -> Result String Admin
parseLogin responseString =
    decodeString decodeAdmin responseString

decodeAdmin : Decoder Admin
decodeAdmin = 
    decode Admin
        |> required "admin" bool

parsePaperList : String -> Result String PaperList
parsePaperList responseString =
    decodeString decodePaperList responseString

decodePaperList : Decoder PaperList
decodePaperList =
    decode PaperList
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
        |> required "link_text" string
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
