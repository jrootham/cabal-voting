import Html exposing (Html, div, text)

main =
  Html.beginnerProgram { model = model, view = view, update = update }

-- MODEL

type alias Model = String

model : Model
model = "Hello world"

-- UPDATE

type Msg = Reset

update : Msg -> Model -> Model
update msg model =
  case msg of
    Reset ->  model

-- VIEW

view : Model -> Html Msg
view model =
  div [] [text model]