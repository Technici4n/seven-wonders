module Messages.Inbound exposing (..)

import Json.Decode as Decode
import Json.Decode exposing (Decoder, at, string, int, list, index, maybe)

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
  , cards : Maybe (List Card)
  }

type alias ActiveGameInfo =
  { name : String
  , playerCount : Int
  , connectedPlayers : List String
  , game : Maybe Game
  }

type alias Game =
  { players : List PlayerData
  , age : Int
  }

type alias ResourceArray = List Int

type alias PlayerData =
  { boardCards : List Card
  , resourceProductions : List (List ResourceArray)
  , adjacentResourceCosts : List ResourceArray
  , gold : Int
  }

type alias Card =
  { name : String
  , goldCost : Int
  , resourceCost : ResourceArray
  , effect : CardEffect
  , chainingTargets : List String
  , chainingSources : List String
  }

type CardEffect
  = Resources ResourceArray
  | Points Int
  | RawMaterialsCost Int
  | ManufacturedProductsCost
  | Shields Int
  | Science Int

-- DECODERS

gameInfo : Decoder GameInfo
gameInfo =
  Decode.map3 GameInfo
    (at ["name"] string)
    (at ["player_count"] int)
    (at ["connected_players"] (list string))
  
playerInfo : Decoder PlayerInfo
playerInfo =
  Decode.map2 PlayerInfo
    (at ["player_name"] string)
    (at ["cards"] (maybe (list card)))

activeGameInfo : Decoder ActiveGameInfo
activeGameInfo =
  Decode.map4 ActiveGameInfo
    (at ["name"] string)
    (at ["player_count"] int)
    (at ["connected_players"] (list string))
    (at ["game"] (maybe game))
  
game : Decoder Game
game =
  Decode.map2 Game
    (at ["players"] (list playerData))
    (at ["age"] int)

playerData : Decoder PlayerData
playerData =
  Decode.map4 PlayerData
    (at ["board_cards"] (list card))
    (at ["resource_productions"] (list (list resourceArray)))
    (at ["adjacent_resource_costs"] (list resourceArray))
    (at ["gold"] int)
  
card : Decoder Card
card =
  Decode.map6 Card
    (at ["name"] string)
    (at ["gold_cost"] int)
    (at ["resource_cost"] resourceArray)
    (at ["effect"] cardEffect)
    (at ["chaining_targets"] (list string))
    (at ["chaining_sources"] (list string))
  
resourceArray : Decoder ResourceArray
resourceArray = list int

cardEffect : Decoder CardEffect
cardEffect =
  Decode.oneOf
    [ at ["Resources"] (Decode.map Resources resourceArray)
    , at ["Points"] (Decode.map Points int)
    , at ["RawMaterialsCost"] (Decode.map RawMaterialsCost int)
    , at ["ManufacturedProductsCost"] (Decode.succeed ManufacturedProductsCost)
    , at ["Shields"] (Decode.map Shields int)
    , at ["Science"] (Decode.map Science int)
    ]

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