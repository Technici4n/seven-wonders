port module Websocket exposing (listen, send)

import Json.Encode as E

port listen : (String -> msg) -> Sub msg

port send : String -> Cmd msg