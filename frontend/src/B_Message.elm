module B_Message exposing (Msg(..), NewGameMessage(..))

import A_Model exposing (PlayerAction)

type Msg
  -- Message from server via WebSockets
  = WsMessage String
  -- Lobby messages
  | NewGame NewGameMessage
  | NewPlayerName String
  | JoinGame String
  -- Game messages
  | PerformAction PlayerAction

type NewGameMessage
  = AddGame
  | GameName String
  | PlayerCount Int