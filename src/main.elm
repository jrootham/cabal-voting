import Html exposing (Html, div, input, button, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import BasicAuth exposing (buildAuthorizationHeader)

main =
  Html.beginnerProgram { model = model, view = view, update = update }

-- MODEL

type alias Model = {
    loggedin : Bool,
    name : String,
    password : String
}

model : Model
model = Model False "" ""

-- UPDATE

type Msg = Name String 
    | Password String
    | Login

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Name newname -> 
        ({ model | name = newname}, Cmd.none)

    Password newpassword -> 
        ({ model | password = newpassword}, Cmd.none)

    Login ->
        (model, loginHTTP)

-- VIEW
view : Model -> Html Msg
view model =
    if model.loggedin then
        div [] [text "logged in"]
    else
        passwordPage model

passwordPage : Model -> Html Msg
passwordPage model =
    div []
    [
        div []
        [ 
            div[] [input [ placeholder "Name", onInput Name ] []],
            div[] [input [ placeholder "Password", onInput Password ] []],
            div[] [button [onClick Login] [text "Login"]]
        ]
            --div[] [text (buildAuthorizationHeader model.login model.password)]
    ]
