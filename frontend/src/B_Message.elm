module B_Message exposing (Msg(..), NewGameMessage(..))

import A_Model exposing (PlayerAction, RenderParameters, Textures)


type
    Msg
    -- Asset loading
    = RenderParametersLoaded (Maybe RenderParameters)
    | TexturesLoaded (Maybe Textures)
      -- Message from server via WebSockets
    | WsMessage String
      -- Lobby messages
    | NewGame NewGameMessage
    | NewPlayerName String
    | JoinGame String
      -- Game messages
    | PerformAction PlayerAction
    | ChangeShownPlayer Int
    | CenterShownPlayer


type NewGameMessage
    = AddGame
    | GameName String
    | PlayerCount Int
