module Parse exposing
    ( parseClosedPaperList
    , parseLogin
    , parseOpenPaperList
    , parsePaperList
    , parseRules
    , parseUserList
    )

import Date
import Http exposing (Response)
import Json.Decode exposing (Decoder, andThen, bool, decodeString, fail, int, list, string, succeed)
import Json.Decode.Pipeline exposing (decode, required)
import Result
import Types exposing (..)


parseClosedPaperList : String -> Result String ClosedPaperList
parseClosedPaperList responseString =
    decodeString decodeClosedPaperList responseString


decodeClosedPaperList : Decoder ClosedPaperList
decodeClosedPaperList =
    decode ClosedPaperList
        |> required "paper_list" (list decodeClosedPaper)


decodeClosedPaper : Decoder ClosedPaper
decodeClosedPaper =
    decode ClosedPaper
        |> required "paper_id" int
        |> required "closed_at" dateDecoder
        |> required "title" string
        |> required "paper_comment" string


parseOpenPaperList : String -> Result String OpenPaperList
parseOpenPaperList responseString =
    decodeString decodeOpenPaperList responseString


decodeOpenPaperList : Decoder OpenPaperList
decodeOpenPaperList =
    decode OpenPaperList
        |> required "paper_list" (list decodeOpenPaper)


decodeOpenPaper : Decoder OpenPaper
decodeOpenPaper =
    decode OpenPaper
        |> required "paper_id" int
        |> required "title" string
        |> required "paper_comment" string
        |> required "total_votes" int


parseUserList : String -> Result String UserList
parseUserList responseString =
    decodeString decodeUserList responseString


decodeUserList : Decoder UserList
decodeUserList =
    decode UserList
        |> required "user_list" (list decodeUser)


decodeUser : Decoder User
decodeUser =
    decode User
        |> required "user_id" int
        |> required "name" string
        |> required "valid" bool
        |> required "admin" bool


parseRules : String -> Result String Rules
parseRules responseString =
    decodeString decodeRules responseString


decodeRules : Decoder Rules
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
