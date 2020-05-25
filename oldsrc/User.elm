module User exposing (editUser, userPage)

import Common exposing (normalFlatButton)
import Html exposing (Html, div, input, label, table, td, text, th, thead, tr)
import Html.Attributes exposing (checked, class, type_, value)
import Html.Events exposing (onCheck, onInput)
import Types exposing (..)


userPage : Model -> Html Msg
userPage model =
    case getUserList model of
        Just users ->
            div []
                [ div []
                    [ div [ class "group" ] [ normalFlatButton model.debounce (EditUser newUser) "Add" ]
                    , div [ class "group" ] [ normalFlatButton model.debounce Reload "Done" ]
                    ]
                , displayList model users
                ]

        Nothing ->
            div [] [ text "No user list. should not happen" ]


displayList : Model -> List User -> Html Msg
displayList model userList =
    div []
        [ table []
            (thead []
                [ tr []
                    [ th [] [ text "Name" ]
                    , th [] [ text "Admin" ]
                    , th [] [ text "Valid" ]
                    , th [] [ text "Edit" ]
                    ]
                ]
                :: List.map (displayUser model) (List.sortBy .name userList)
            )
        ]


displayUser : Model -> User -> Html Msg
displayUser model user =
    tr []
        [ td [] [ text user.name ]
        , td [] [ text (toString user.admin) ]
        , td [] [ text (toString user.valid) ]
        , td [] [ normalFlatButton model.debounce (EditUser user) "Edit" ]
        ]


editUser : Model -> Html Msg
editUser model =
    case getEditUser model of
        Just user ->
            userForm model user

        Nothing ->
            div [] [ text "No user.  Should not happen." ]


userForm : Model -> User -> Html Msg
userForm model user =
    div []
        [ userValues user
        , div []
            [ div [ class "group" ] [ normalFlatButton (canSave model) UpdateUser "Save" ]
            , div [ class "group" ] [ normalFlatButton model.debounce CloseUser "Cancel" ]
            ]
        ]


userValues : User -> Html Msg
userValues user =
    div []
        [ div [] [ label [] [ text "Name  ", input [ type_ "text", value user.name, onInput UserName ] [] ] ]
        , div [] [ label [] [ text "Admin ", input [ type_ "checkbox", checked user.admin, onCheck UserAdmin ] [] ] ]
        , div [] [ label [] [ text "Valid ", input [ type_ "checkbox", checked user.valid, onCheck UserValid ] [] ] ]
        ]


canSave : Model -> Bool
canSave model =
    case getEditUser model of
        Just user ->
            model.debounce && (user.name /= "")

        Nothing ->
            False
