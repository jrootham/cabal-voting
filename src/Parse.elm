module Parse exposing (Paper, Link, Vote, parse)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Result
import Date

type alias Paper =
    { id : Int
    , title : String
    , paper : Link
    , comment : String
    , references : List Link
    , createdAt : Date.Date
    , submitter : String
    , votes : List Vote
    }

type alias Link =
    { index : Int
    , text: String
    , link: String
    }   

type alias Vote =
    {
        name: String
        , votes : Int
    }

parse : String -> Result String (List Paper)
parse responseString =
    if False then
        Ok []
    else
        Err "Not implemented"

decodePaper : Decoder Paper
decodePaper =
    decode Paper
        |> required "id" int
        |> required "title" string
        |> required "paper" linkDecoder
        |> required "comment" string
        |> required "references" (list linkDecoder)
        |> required "createdAt" dateDecoder
        |> required "submitter" (field "login" string)
        |> required "votes" (list voteDecoder)


linkDecoder : Decoder Link
linkDecoder =
    decode Link
        |> required "index" int
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
