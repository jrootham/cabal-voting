module Parse exposing (Paper, Link)

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
    , votes : List String
    }

type alias Link =
    { text: String
    , link: String
    }   

decodePaper : Decoder Paper
decodePaper =
    decode Paper
        |> required "id" int
        |> required "title" string
        |> required "paper" linkDecoder
        |> required "comment" string
        |> required "references" (list linkDecoder)
        |> required "createdAt" dateDecoder
        |> required "author" (field "login" string)
        |> required "reactions" voteDecoder


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


voteDecoder : Decoder (List String)
voteDecoder =
    at [ "nodes" ] (list (at [ "user", "login" ] string))


