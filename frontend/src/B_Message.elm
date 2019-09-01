module B_Message exposing (Msg(..), NewGameMessage(..))

type Msg
  -- Message from server via WebSockets
  = WsMessage String
  -- Lobby messages
  | NewGame NewGameMessage
  | NewPlayerName String
  | JoinGame String

type NewGameMessage
  = AddGame
  | GameName String
  | PlayerCount Int