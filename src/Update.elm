module Update exposing(updateLogin, handleResponse, addPaper, editPaper, cancel, updatePaper
  , updateTitle, updateComment, updatePaperLink, addReference, deleteReference, updateReference
  , setReferenceText, setReferenceLink, save, close, launchClose, increment, decrement)

import List as L
import Http
import Time
import Task

import Model as M
import Common as C

updateLogin : M.Model -> Result Http.Error (Maybe M.User) -> M.Model
updateLogin model result =
  case result of
    Ok user ->
      model
        |> M.setDebounce False
        |> M.setUser user

    Err error ->
      model
        |> M.setDebounce True
        |> M.setError (M.HttpError error)

handleResponse : M.Model -> Result Http.Error M.Response -> M.Model
handleResponse model response =
  let
    newModel = M.setDebounce True model
  in
    case response of
      Ok actual ->
        case actual.error of
          Just message ->
            M.setError (M.RemoteError message) newModel

          Nothing ->
            case actual.data of
              Just data ->
                M.setData data newModel

              Nothing ->
                M.setError (M.LocalError "Missing both error and data") newModel

      Err error ->
        M.setError (M.HttpError error) newModel


addPaper : M.Model -> Time.Posix -> M.Model
addPaper model now =
  let
    user = M.getUser model
  in
    case user of
      Just userValue ->
        model
          |> M.setDebounce True
          |> M.setPage M.Edit
          |> M.setEditingPaper (M.newPaper userValue now)
 
      Nothing ->
        M.setError (M.LocalError "Creating paper without a signed on user") model

editPaper : M.Model -> M.Paper -> M.Model
editPaper model paper =
  let
    user = M.getUser model
  in
    case user of
      Just userValue ->
        model
          |> M.setDebounce True
          |> M.setPage M.Edit
          |> M.setEditingPaper paper
 
      Nothing ->
        M.setError (M.LocalError "Editing paper without a signed on user") model

cancel : M.Model -> M.Model
cancel model =
  model 
    |> M.clearEditingPaper
    |> M.setPage M.Display

updatePaper : (valueType -> M.Paper-> M.Paper) -> valueType -> M.Model -> M.Model
updatePaper setter value model =
  case M.getEditingPaper model of
    Just paper ->
      M.setEditingPaper (setter value paper) model

    Nothing ->
      M.setError (M.LocalError "No paper to edit") model
      
updateTitle : String -> M.Paper -> M.Paper
updateTitle title  paper =
  {paper | title = title}

updateComment : String -> M.Paper -> M.Paper
updateComment comment paper =
  {paper | comment = comment}

updatePaperLink : String -> M.Paper -> M.Paper
updatePaperLink link paper =
  {paper | link = link}

addReference : M.Model -> M.Model
addReference model =
  case M.getEditingPaper model of
    Just paper ->
      let
        reference = M.newReference paper
        newPaper = {paper | referenceList = reference :: paper.referenceList}
      in
        M.setEditingPaper newPaper model

    Nothing ->
      M.setError (M.LocalError "No paper to edit") model
    
deleteReference : M.Reference -> M.Paper -> M.Paper
deleteReference reference paper =
  {paper | referenceList = removeReference reference paper.referenceList}

removeReference : M.Reference -> List M.Reference -> List M.Reference
removeReference reference referenceList =
  L.filter (\ r -> r.index /= reference.index) referenceList

updateReference:(valueType->M.Reference->M.Reference)->valueType->M.Reference->M.Model->M.Model
updateReference setter value reference model =
  case M.getEditingPaper model of
    Just paper ->
      let
        newReference = setter value reference
        newList = newReference :: removeReference reference paper.referenceList
        newPaper = {paper | referenceList = newList}
      in
        M.setEditingPaper newPaper model

    Nothing ->
      M.setError (M.LocalError "No paper to edit") model

setReferenceText : String -> M.Reference -> M.Reference
setReferenceText text reference =
  {reference | text = text}

setReferenceLink : String-> M.Reference -> M.Reference
setReferenceLink link reference =
  {reference | link = link}
  

save : M.Model -> (M.Model, Cmd M.Msg)
save model =
  case M.getEditingPaper model of
    Just paper ->
      let
        newModel =
          model
            |> M.setDebounce False 
            |> M.setPage M.Display
      in
        (newModel, Http.post {url = "save", body = M.paperPayload paper, expect = C.expect})

    Nothing ->
      (M.setError (M.LocalError "No paper to save") model, Cmd.none) 

launchClose : M.Model -> M.Paper -> (M.Model, Cmd M.Msg)
launchClose model paper =
  let
    newModel =
      model
        |> M.setDebounce False
        |> M.setEditingPaper paper
  in
    (newModel, Task.perform M.DoClose Time.now)

close : M.Model -> Time.Posix -> (M.Model, Cmd M.Msg)
close model time =
  case M.getEditingPaper model of
    Just paper ->
      let
        body = M.closePayload paper time
        newModel =
          model
            |> M.clearEditingPaper
            |> M.setDebounce False
      in
        ( newModel, Http.post {url = "close", body = body, expect = C.expect})

    Nothing ->
      (M.setError (M.LocalError "No paper to close") model, Cmd.none) 

increment : M.Model -> M.Paper -> ( M.Model, Cmd M.Msg )
increment model paper =
  let
    newModel = M.setDebounce False model
    body = M.votePayload paper
  in
    (newModel, Http.post {url = "vote", body = body, expect = C.expect})

decrement : M.Model -> M.Paper -> ( M.Model, Cmd M.Msg )
decrement model paper =
  let
    newModel = M.setDebounce False model
    body = M.votePayload paper
  in
    (newModel, Http.post {url = "unvote", body = body, expect = C.expect})
