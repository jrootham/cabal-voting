module Payload exposing (loginPayload, paperPayload, votePayload, closePayload)

import Parse exposing(Paper, Reference, Link)
import Json.Encode exposing (..)

type alias PayloadElement = (String, Value)

makePayload : (List PayloadElement) -> String
makePayload payloadList =      
  encode 0 (object payloadList)

userElement : String -> PayloadElement
userElement user =      
  ("user", string user)

loginPayload : String -> String
loginPayload user = 
  makePayload [userElement user]   

paperPayload : String -> Paper -> String
paperPayload user paper =
  makePayload [userElement user, paperElement paper]

paperElement : Paper -> PayloadElement
paperElement paper =
  ("paper", paperContents paper)

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

votePayload : String -> Int -> Int-> String
votePayload name paperId increment = 
  makePayload  [userElement name, ("paper_id", int paperId), ("increment", int increment)]

closePayload : String -> Int -> String
closePayload name paperId = 
  makePayload  [userElement name, ("close", bool True), ("paper_id", int paperId)]



