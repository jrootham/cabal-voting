module DisplayPage exposing (page)

import List
import String
import Html as H
import Html.Attributes as A
import Html.Events as E
import Time as T

import Common as C
import Model as M

page : M.Model -> H.Html M.Msg
page model =
  H.div []
    [ userData model
    , pickOrder model
    , actions model
    , displayPaperList model
    ]

-- Total paper count display
-- Also user specific data display

userData : M.Model -> H.Html M.Msg
userData model =
  case model.currentUser of
  Just user ->
    let
      paperCount =
        List.length (List.filter (\paper -> user == paper.submitter)  model.data.paperList)
      paperString = String.fromInt paperCount
      maxPaperString = String.fromInt (M.getMaxPapers model)
      voteString = String.fromInt (countVotes model)
      maxVoteString = String.fromInt model.data.rules.maxVotes
      submitString = " submitted " ++ paperString ++ " of " ++ maxPaperString ++ " possible\n"
      votingString = " cast  " ++ voteString ++ " of " ++ maxVoteString ++ " possible votes\n"
      totalString = "out of " ++ String.fromInt (List.length (M.getPaperList model)) 
        ++ " total submitted."
    in

      H.div [] 
        [ H.div [] [H.h2 [] [H.text ("User: " ++ user)]]
        , H.div [A.id "user-data"] 
          [ H.div [] [H.text submitString]
          , H.div [] [H.text votingString]
          , H.div [] [H.text totalString]
          ]
        ]

  Nothing ->
    H.div [] 
      [ H.div [] [H.h2 [] [H.text "User: Guest"]]
      , H.div [] 
        [
          H.text (String.fromInt (List.length (M.getPaperList model)) ++ " total submitted")
        ]
      ]

-- pick order radio buttons and supporting functions

pickOrder : M.Model -> H.Html M.Msg
pickOrder model =
  let
    radio = outerOrder model
  in
    H.div []
      [ H.div [] [H.text "Order: "]
      , H.div [ A.id "order" ]
        [ radio " Title " M.Title
        , radio " Earliest " M.Earliest
        , radio " Latest " M.Latest
        , radio " Most votes " M.MostVotes
        , radio " Least votes " M.LeastVotes
        , radio " Submitter " M.Submitter

        , if model.currentUser /= Nothing then
            radio " My Papers " M.Mine
          else
            H.div [] []

        , H.div []
          [ innerOrder model " Voter " M.Voter
          , H.select []
            (List.map
              (\voter ->
                H.option
                  [ A.value voter
                  , E.onClick (M.ChangeVoter voter)
                  , A.selected (voter == (M.getSortByVoter model))
                  ]
                  [ H.text voter ]
              )
              (M.getVoterList model)
            )
          ]
        ]
      ]

makeCompare model =
  case (M.getOrder model) of
  M.Title ->
    totalOrder (\left right -> left.title < right.title)

  M.Earliest ->
    totalOrder (\left right -> 
     (T.posixToMillis left.createdAt) < (T.posixToMillis right.createdAt))

  M.Latest ->
    totalOrder (\left right -> 
      (T.posixToMillis right.createdAt) < (T.posixToMillis left.createdAt))

  M.MostVotes ->
    totalOrder (\left right -> sumVotes right.voteList < sumVotes left.voteList)

  M.LeastVotes ->
    totalOrder (\left right -> sumVotes left.voteList < sumVotes right.voteList)

  M.Submitter ->
    totalOrder (\left right -> left.submitter < right.submitter)

  M.Mine ->
    case model.currentUser of
      Just name ->
        mineOrder name

      Nothing ->
        totalOrder (\left right -> left.submitter < right.submitter)

  M.Voter ->
    votesByUser (M.getSortByVoter model)


outerOrder : M.Model -> String -> M.PaperOrder -> H.Html M.Msg
outerOrder model labelText order =
  H.div [] [innerOrder model labelText order]

innerOrder : M.Model -> String -> M.PaperOrder -> H.Html M.Msg
innerOrder model labelText order =
  H.label []
    [ H.input
        [ A.type_ "radio"
        , A.name "change-order"
        , E.onClick (M.ChangeOrder order)
        , A.checked ((M.getOrder model) == order)
        , A.disabled False
        ]
        []
    , H.text labelText
    ]


-- Global actions

actions : M.Model -> H.Html M.Msg 
actions model =
  H.div []
    [ C.normalFlatButton ((M.getDebounce model) && validateAdd model) M.Add "Add"
    , C.normalFlatButton (M.getDebounce model) M.Reload "Reload"
    ]


--  Papers

displayPaperList : M.Model -> H.Html M.Msg
displayPaperList model =
  let
    compare = makeCompare model
    titles =
        [ H.div [A.class "heading"] [ H.text "Submitter" ]
        , H.div [A.class "heading"] [ H.text "Contents" ]
        , H.div [A.class "heading"] [ H.text "Vote" ]
        , H.div [A.class "heading"] [ H.text "Voters" ]
      ]
    htmlList = 
      M.getPaperList model
        |> List.sortWith compare
        |> List.map (displayPaper model)
        |> List.foldr List.append []
        |> List.append titles 
  in
    H.div [A.id "paper-base"] htmlList

sumVotes : List M.Vote -> Int
sumVotes voteList =
  List.sum (List.map .votes voteList)

voteTable : List M.Vote -> List (H.Html M.Msg)
voteTable listOfVotes =
  let
    rawDisplayVotes =
      \name votes -> 
        H.tr [] [H.td [A.class "vote-name"] [H.text name], H.td [] [H.text (String.fromInt votes)]]

    displayVotes =
      \vote -> rawDisplayVotes vote.user vote.votes

    totalVotes =
      \voteList -> rawDisplayVotes "Total" (List.sum (List.map .votes voteList))
  in
    [ H.table [] (totalVotes listOfVotes :: List.map displayVotes listOfVotes) ]


displayPaper : M.Model -> M.Paper -> List (H.Html M.Msg)
displayPaper model paper =
  [submitterAndActions model paper, contents paper, voting model paper, voters paper]

testVote : M.Model -> (M.Vote -> Bool)
testVote model =
  case model.currentUser of
    Just user ->
      \vote -> vote.user == user

    Nothing ->
      \vote -> False

thisVoterCount : M.Model -> M.Paper -> Int
thisVoterCount model paper =
  let
    possible = List.head (List.filter (testVote model) paper.voteList)
  in
    case possible of
      Just vote ->
        vote.votes

      Nothing ->
        0

belongsTo : M.Model -> M.Paper -> Bool
belongsTo model paper =
  case model.currentUser of
    Just user ->
      user == paper.submitter

    Nothing ->
      False

submitterAndActions : M.Model -> M.Paper -> H.Html M.Msg
submitterAndActions model paper = 
  let ownerOf = belongsTo model paper
  in
    H.div []
      [ H.div [ A.class "submitter" ] [ H.text paper.submitter ]
      , C.normalFlatButton ownerOf (M.DoEdit paper) "Edit"
      , C.normalFlatButton ((M.getDebounce model) && ownerOf) (M.Close paper) "Close"
      ]

contents : M.Paper -> H.Html M.Msg
contents paper =
  H.div []
    (
      [ H.div [A.class "paper-title"] [ C.makeLink paper.title paper.link ]
      , H.div [ A.class "contents" ] (makeParagraphs paper.comment)
      ]
      ++ (List.map 
          (\ref -> H.div [] [ C.makeLink ref.text ref.link ]) 
          (List.sortBy .index paper.referenceList)
        )
    )

makeParagraphs comment =
  List.map (\line -> H.p [A.class "comment"] [H.text line]) (String.split "\n" comment)

voting : M.Model -> M.Paper -> H.Html M.Msg
voting model paper =
  let count = thisVoterCount model paper
  in
    H.div []
      [ C.thinFlatButton (canDecrement count model) (M.DecrementVote paper) "-"
      , H.text " "
      , H.text (String.fromInt count)
      , H.text " "
      , C.thinFlatButton (canIncrement count model) (M.IncrementVote paper) "+"
      ]

voters : M.Paper -> H.Html M.Msg
voters paper =
  H.div [] (voteTable paper.voteList)

canDecrement : Int -> M.Model -> Bool
canDecrement votes model =
  (model.currentUser /= Nothing) && (M.getDebounce model) && votes > 0


canIncrement : Int -> M.Model -> Bool
canIncrement votes model =
  (model.currentUser /= Nothing) && (M.getDebounce model) && voteLimit model votes


countVotes : M.Model -> Int
countVotes model =
  let
    inner : M.Vote -> Int -> Int
    inner =
      \vote count -> count + vote.votes

    filter : M.Vote -> Bool
    filter =
      case model.currentUser of
        Just user ->
          \vote -> vote.user == user

        Nothing ->
          \vote -> False

    outer : M.Paper -> Int -> Int
    outer =
      \paper count -> List.foldl inner count (List.filter filter paper.voteList)
  in
    List.foldl outer 0 (M.getPaperList model)


voteLimit : M.Model -> Int -> Bool
voteLimit model voterCount =
  let
    available = (M.getMaxVotes model) - countVotes model
  in
    (available > 0) && (M.getMaxPerPaper model > voterCount)


validateAdd : M.Model -> Bool
validateAdd model =
  case model.currentUser of
    Just user ->
      let
        submitterFilter = \paper -> user == paper.submitter
        paperCount = List.length (List.filter submitterFilter (M.getPaperList model))
      in
        M.getMaxPapers model > paperCount

    Nothing ->
      False

nameIn : String -> M.Paper -> Bool
nameIn name paper =
  List.member name (List.map (\vote -> vote.user) paper.voteList)


getVotes : String -> List M.Vote -> Int
getVotes name voteList =
  let
      entry =
          List.head (List.filter (\vote -> vote.user == name) voteList)
  in
  case entry of
      Just vote ->
          vote.votes

      Nothing ->
        0

compareVotes : String -> List M.Vote -> List M.Vote -> Order
compareVotes name left right =
  if getVotes name left == getVotes name right then
      EQ

  else if getVotes name left < getVotes name right then
      GT

  else
      LT


votesByUser : String -> (M.Paper -> M.Paper -> Order)
votesByUser name =
  let
      voterIn =
          nameIn name
  in
  \left right ->
      if voterIn left && voterIn right then
          compareVotes name left.voteList right.voteList

      else if not (voterIn left) && voterIn right then
          GT

      else if voterIn left && not (voterIn right) then
          LT

      else
          EQ


totalOrder : (M.Paper -> M.Paper -> Bool) -> M.Paper -> M.Paper -> Order
totalOrder lessThan left right =
  if lessThan left right then
      LT

  else if lessThan right left then
      GT

  else
      EQ


mineOrder : String -> (M.Paper -> M.Paper -> Order)
mineOrder name =
  \left right ->
      if (left.submitter == name) && (right.submitter == name) then
          EQ

      else if (left.submitter == name) && (right.submitter /= name) then
          LT

      else if (left.submitter /= name) && (right.submitter == name) then
          GT

      else if left.submitter == right.submitter then
          EQ

      else if left.submitter < right.submitter then
          LT

      else 
          GT

