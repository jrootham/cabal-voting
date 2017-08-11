module Payload exposing (makePayload, Owner, Name, Send)

import Json.Encode exposing (..)


type alias Owner =
    String


type alias Name =
    String


type alias Send =
    String


makePayload : Owner -> Name -> Send
makePayload owner name =
    let
        fromGraphQLi =
            """
  query repo($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    issues(first: 100, states: [OPEN]) {
      nodes {
        title
        body
        createdAt
        author {
          login
        }
        reactions(first: 100, content: THUMBS_UP) {
          nodes {
            user {
              login
            }
          }
        }
      }
    }
  }
}
"""

        ship =
            String.join " " (String.lines fromGraphQLi)

        vars =
            object [ ( "owner", string owner ), ( "name", string name ) ]
    in
        encode 0 (object [ ( "query", string ship ), ( "variables", vars ) ])