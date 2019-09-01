module C_Data exposing (..)

import A_Model exposing (Card, Game, GameInfo)

{-
  From server to client
-}

type ToPlayer
  = GameList (List GameInfo)
  | ActiveGame PlayerInfo ActiveGameInfo

type alias PlayerInfo =
  { playerName : String
  , cards : Maybe (List Card)
  }

type alias ActiveGameInfo =
  { name : String
  , playerCount : Int
  , connectedPlayers : List String
  , game : Maybe Game
  }

{-
  From client to server
-}

type FromPlayer
  = CreateGame String Int
  | Connect ConnectInfo

type alias ConnectInfo =
  { gameName : String
  , playerName : String
  }