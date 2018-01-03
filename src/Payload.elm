module Payload exposing (loginPayload, paperPayload, votePayload, closePayload)

import Json.Encode exposing (Value, object, string, int, list)
import Http exposing (Body, jsonBody)

import Types exposing(..)

loginPayload : String -> Body
loginPayload user = 
  jsonBody (object [("user", (string user))])

paperPayload : Paper -> Body
paperPayload paper =
  jsonBody (object [("paper", paperContents paper)])

paperContents : Paper -> Value
paperContents paper = 
  object
    [ ("paper_id", int paper.id)
    , ("title", string paper.title)
    , ("paper", linkContents paper.paper)
    , ("comment", string paper.comment)
    , ("references", (referenceListContents paper.references))
    ]

linkContents : Link -> Value
linkContents link = 
  object[("link_text", string link.text), ("link", string link.link)]

referenceContents : Reference -> Value
referenceContents reference =
  object [("index", int reference.index), ("link", linkContents reference.link)]

referenceListContents : (List Reference) -> Value
referenceListContents references =
  list (List.map (\ reference -> referenceContents reference) references)

votePayload : Int -> Body
votePayload paperId = 
  jsonBody (object [("paper_id", int paperId)])

closePayload : Int -> Body
closePayload paperId = 
  jsonBody (object [("paper_id", int paperId)])



