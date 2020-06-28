module EditPage exposing (page)

import Http
import Html as H
import Html.Attributes as A
import Html.Events as E
import Time
import Task

import Common as C
import Model as M

page : M.Model -> H.Html M.Msg
page model =
  H.div [] 
  [
    case M.getEditingPaper model of
      Just paper ->
        H.div [] 
        [
          H.div [A.id "paper-data"]
          [ H.div [] [ inputDiv "Title: " paper.title M.InputTitle ]
          , H.div [] [ editPaperLink paper ]
          , H.div []
            [ H.div [ A.class "label" ]
              [ H.text "Comment: " ]
            , H.textarea [ A.cols 80, E.onInput M.InputComment ] [ H.text paper.comment ]
            ]
          , H.div [] [ H.div 
            [ A.class "label" ] [ H.text "References: " ]
            , editReferences paper.id paper.referenceList
            ]
          ]
        , H.div []
          [ C.normalFlatButton (M.getDebounce model) M.Save "Save"
          , C.normalFlatButton True M.Cancel "Cancel"
          ]
        ] 

      Nothing ->
        H.div [] [ H.text "Paper not found.  Should not occur." ]
  ]

editReferences : Int -> List M.Reference -> H.Html M.Msg
editReferences paperId references =
    H.div []
        [ H.div [] [ H.div [] [ C.wideFlatButton True M.AddReference "Add reference" ] ]
        , H.div [] [ H.div [] (List.map editReference (List.sortBy .index references)) ]
        ]




editReference : M.Reference -> H.Html M.Msg
editReference reference =
    H.div []
        [ C.widerFlatButton True (M.DeleteReference reference) "Delete reference"
        ,  H.div []
          [ inputDiv "Link text: " reference.text (M.InputReferenceText reference)
          , urlDiv "Link: " reference.link (M.InputReferenceLink reference)
          ]
        ]


editPaperLink : M.Paper -> H.Html M.Msg
editPaperLink paper =
  H.div [][urlDiv "Link: " paper.link M.InputPaperLink ]


inputDivBase : String -> String -> String -> (String -> M.Msg) -> H.Html M.Msg
inputDivBase typeName label currentValue makeMessage =
    H.div [] [ H.div [ A.class "label" ] 
      [H.text label ], H.input [ A.type_ typeName, A.value currentValue, E.onInput makeMessage ] []]

inputDiv =
    inputDivBase "text"

urlDiv =
    inputDivBase "url"

