module Messages.Inbound exposing (..)

import Json.Decode as Decode
import Json.Decode exposing (Decoder, at, string, int, list, index)

-- MESSAGES

type ToPlayer
  = GameList (List GameInfo)
  | ActiveGame PlayerInfo ActiveGameInfo

type alias GameInfo =
  { name : String
  , playerCount : Int
  , connectedPlayers : List String
  }

type alias PlayerInfo =
  { playerName : String
  }

type alias ActiveGameInfo =
  { name : String
  , playerCount : Int
  , connectedPlayers : List String
  }

-- DECODERS

gameInfo : Decoder GameInfo
gameInfo =
  Decode.map3 GameInfo
    (at ["name"] string)
    (at ["player_count"] int)
    (at ["connected_players"] (list string))
  
playerInfo : Decoder PlayerInfo
playerInfo =
  Decode.map PlayerInfo
    (at ["player_name"] string)

activeGameInfo : Decoder ActiveGameInfo
activeGameInfo =
  Decode.map3 ActiveGameInfo
    (at ["name"] string)
    (at ["player_count"] int)
    (at ["connected_players"] (list string))

toPlayer : Decoder ToPlayer
toPlayer =
  Decode.oneOf
    [ at ["GameList"] (Decode.map GameList (list gameInfo))
    , at ["ActiveGame"] (
      Decode.map2 ActiveGame
        (index 0 playerInfo)
        (index 1 activeGameInfo)
      )
    ]