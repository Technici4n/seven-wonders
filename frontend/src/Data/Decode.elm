module Data.Decode exposing (decodeToPlayer)

import A_Model exposing
  ( Card
  , CardEffect(..)
  , ChoseResourcesData
  , ChoosingResourcesData
  , Game
  , GameInfo
  , Play(..)
  , PlayerData
  , ResourceAllocation
  , ResourceAllocationVerdict
  , ResourceArray
  )
import C_Data exposing (ActiveGameInfo, PlayerInfo, ToPlayer(..))
import Json.Decode as Decode
import Json.Decode exposing (at, index, int, list, maybe, string, Decoder)

decodeToPlayer : String -> Result String ToPlayer
decodeToPlayer src =
  src
    |> Decode.decodeString toPlayer
    |> Result.mapError Decode.errorToString

exact : a -> Decoder a -> Decoder a
exact value src =
  src
  |> Decode.andThen (\x -> if x == value then Decode.succeed x else Decode.fail "Wrong value")

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

gameInfo : Decoder GameInfo
gameInfo =
  Decode.map3 GameInfo
    (at ["name"] string)
    (at ["player_count"] int)
    (at ["connected_players"] (list string))
  
playerInfo : Decoder PlayerInfo
playerInfo =
  Decode.map3 PlayerInfo
    (at ["player_name"] string)
    (at ["cards"] (maybe (list card)))
    (at ["play"] (maybe play))

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
    , exact "ManufacturedProductsCost" string |> Decode.map (always ManufacturedProductsCost)
    , at ["Shields"] (Decode.map Shields int)
    , at ["Science"] (Decode.map Science int)
    ]

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
    (at ["resource_costs"] (list resourceArray))
    (at ["gold"] int)
  
play : Decoder Play
play =
  Decode.oneOf
  [ at ["NoAction"] (Decode.succeed NoAction)
  , at ["ChoosingResources"] (Decode.map ChoosingResources choosingResourcesData)
  , at ["ChoseResources"] (Decode.map ChoseResources choseResourcesData)
  ]

choosingResourcesData : Decoder ChoosingResourcesData
choosingResourcesData =
  Decode.map3 ChoosingResourcesData
    (at ["card_index"] int)
    (at ["resource_allocation"] resourceAllocation)
    (at ["verdict"] resourceAllocationVerdict)

choseResourcesData : Decoder ChoseResourcesData
choseResourcesData =
  Decode.map2 ChoseResourcesData
    (at ["card_index"] int)
    (at ["resource_allocation"] resourceAllocation)

resourceAllocation : Decoder ResourceAllocation
resourceAllocation =
  list (list int)

resourceAllocationVerdict : Decoder ResourceAllocationVerdict
resourceAllocationVerdict =
  Decode.map3 ResourceAllocationVerdict
    (at ["extra_resources"] resourceArray)
    (at ["missing_resources"] resourceArray)
    (at ["missing_gold"] int)