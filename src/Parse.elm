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

type alias Paper =
    { title : String
    , createdAt : Date.Date
    , submitter : String
    , votes : List String
    }

decodePaper : Decoder Paper
decodePaper =
    decode Paper
        |> required "title" string
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


decodeNameAndPaperList : Decoder NameAndPaperList
decodeNameAndPaperList =
    decode NameAndPaperList
        |> requiredAt [ "viewer", "login"] string 
        |> requiredAt [ "repository", "issues", "nodes" ] (list decodePaper)

parse : String -> Result String NameAndPaperList
parse response =
    decodeString (at [ "data" ] decodeNameAndPaperList) response

