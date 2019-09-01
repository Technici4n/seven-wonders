module E_Init exposing (init)

import A_Model exposing (Model(..))
import B_Message exposing (Msg)

init : () -> (Model, Cmd Msg)
init _ =
  (InLobby { playerName = "", games = [], newGameData = { name = "", playerCount = 3 }}, Cmd.none)