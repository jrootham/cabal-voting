import Html exposing (Html, div, input, button, text, h1)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import BasicAuth exposing (buildAuthorizationHeader)

main =
  Html.program { init = init, view = view, update = update, subscriptions = subscriptions}

-- MODEL

type alias Model = {
    loggedin : Bool,
    name : String,
    password : String,
    loginError : String
}

init: (Model, Cmd Msg)
init = (Model False "" "" "", Cmd.none)

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- UPDATE

type Msg = Name String 
    | Password String
    | Login
    | LoginResult (Result Http.Error String)
    | Clear

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Name newname -> 
        ({ model | name = newname}, Cmd.none)

    Password newpassword -> 
        ({ model | password = newpassword}, Cmd.none)

    Login ->
        (model, githubLogin model.name model.password)

    LoginResult(Ok response) ->
        let
            foo = Debug.log "Good response" response
        in
            ({model | loggedin = True}, Cmd.none)

    LoginResult(Err error) ->
        ({model | loginError = formatError error}, Cmd.none)

    Clear ->
        ({model | loginError =""}, Cmd.none)

formatError: Http.Error -> String
formatError error =
    case error of
        Http.BadUrl url ->
            "Bad URL " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus response ->
            let
                foo = Debug.log "Response" response
            in
            response.status.message

        Http.BadPayload explain result->
            explain


view : Model -> Html Msg
view model =
    div [] 
    [
        div[] [h1[] [text "Cabal Voting System"]],

        div[]     
        [
            if model.loggedin then
                div [] [text "logged in"]
            else
                passwordPage model
        ]
    ]

 
passwordPage : Model -> Html Msg
passwordPage model =
    div []
    [
        div []
        [ 
            div[] [input [ placeholder "Name", onInput Name ] []],
            div[] [input [ placeholder "Password", onInput Password ] []],
            div[] [button [onClick Login] [text "Login"]],
            div[] [text model.loginError],
            div[] [button [onClick Clear] [text "Clear error"]]
        ]
    ]

-- Commands

githubLogin: String -> String -> Cmd Msg
githubLogin login password =
    let
        header = [buildAuthorizationHeader login password]
--        url = "https://api.github.com"  
        query = """{ 
   "query": "query {
  repository(owner: "jrootham", name: "cabal-voting") {
    issues(first: 100) {
      nodes {
        title
        body
        author {
          login
        }
        reactions(first: 100) {
          nodes {
            content
            user {
              login
            }
          }
        }
      }
    }
  }
}
" 
}
"""

        query1 = """{"query":"query{viewer{login}}"}"""
        query2 = """{"query":"query{user(login:\\"jrootham\\"){email}}"}"""
        mime = "application/json"

        url = "https://api.github.com/graphql"
        req =   Http.request
            { method = "POST"
            , headers = header
            , url = url
            , body = Http.stringBody mime query2
--            , body = Http.emptyBody
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }        

        foo = Debug.log "Request" req
    in
        Http.send LoginResult req 
            
