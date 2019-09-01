module H_Subscriptions exposing (subscriptions)

import B_Message exposing (Msg(..))
import Websocket exposing (listen)

subscriptions model =
  listen WsMessage