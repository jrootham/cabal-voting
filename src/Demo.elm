module Demo exposing(isUser, getPaperList, newPaper, delete, getPaper)
import Date

import Parse exposing(Paper, Link)

isUser: String -> Bool
isUser name =
   List.member name ["foo", "bar"]

{-type alias Paper =
    { id : Int
    , title : String
    , paper : Link
    , comment : String
    , references : List Link
    , createdAt : Date.Date
    , submitter : String
    , votes : List String
    }
-}

getPaperList =
    let
        date1 = Date.fromTime 1505500143000
        paper1 = Link "Paper" "https://xkcd.com/1866/"
        ref1 = Link "Reference 1" "https://xkcd.com/1863/"   

        date2 = Date.fromTime 1505500148000
        paper2 = Link "Paper" "https://xkcd.com/1860/"
        ref2 = Link "Reference 1" "https://xkcd.com/1858/"   

        date3 = Date.fromTime 1505500155000
        paper3 = Link "Paper" "https://xkcd.com/1840/"
    in
            
    [
        Paper 1 "First paper" paper1 "Teapot Dome" [ref1] date1 "foo" ["foo", "bar"]
        , Paper 2 "Second paper" paper2 "Not a teapot" [ref2] date1 "bar" ["bar"]
        , Paper 3 "Third paper" paper3 "" [] date3 "bar" ["bar"]
    ]

newPaper : String -> Paper
newPaper submitter = 
    Paper 0 "" (Link "Paper" "") "" [] (Date.fromTime 0) submitter []

delete : List Paper -> Int -> List Paper
delete paperList id =
    List.filter (\ paper -> id /= paper.id) paperList            

getPaper : List Paper -> Int -> Maybe Paper
getPaper paperList id =
    List.head (List.filter (\ paper -> id == paper.id) paperList)            
