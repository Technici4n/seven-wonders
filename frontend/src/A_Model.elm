module A_Model exposing (..)

import Data.Font exposing (Font)
import Data.TextureAtlas exposing (TextureAtlas)
import WebGL.Texture exposing (Texture)

type Model
  = InLobby LobbyModel
  | InGame GameModel

{-
  Lobby
-}

type alias LobbyModel =
  { playerName : String
  , games : List GameInfo
  , newGameData : NewGameData
  }

type alias GameInfo =
  { name : String
  , playerCount : Int
  , connectedPlayers : List String
  }

type alias NewGameData =
  { name : String
  , playerCount : Int
  }

{-
  Game
-}

type alias GameModel =
  { renderParameters : Maybe RenderParameters
  , textures : Maybe Textures
  , gameName : String
  , playerName : String
  , playerId : Int
  , playerHand : Maybe (List Card)
  , play : Play
  , playerCount : Int
  , connectedPlayers : List String
  , game : Maybe Game
  , shownPlayer : Int
  }

type alias RenderParameters =
  { atlas : TextureAtlas
  , font : Font
  }

type alias Textures =
  { atlas : Texture
  , text : Texture
  }

type alias Game =
  { players : List PlayerData
  , age : Int
  }

type alias PlayerData =
  { boardCards : List Card
  , resourceProductions : List (List ResourceArray)
  , resourceCosts : List ResourceArray
  , gold : Int
  }

type alias Card =
  { color : CardColor
  , name : String
  , goldCost : Int
  , resourceCost : ResourceArray
  , effect : CardEffect
  , chainingTargets : List String
  , chainingSources : List String
  }

type CardColor
  = Blue
  | Brown
  | Gray
  | Green
  | Purple
  | Red
  | Yellow

type alias ResourceArray = List Int

emptyResourceArray : ResourceArray
emptyResourceArray = List.repeat 7 0

type CardEffect
  = Resources ResourceArray
  | Points Int
  | RawMaterialsCost Int
  | ManufacturedProductsCost
  | Shields Int
  | Science Int

type Play
  = NoAction
  | ChoosingResources ChoosingResourcesData
  | ChoseResources
    { cardIndex : Int
    , resourceAllocation : ResourceAllocation
    }

type alias ChoosingResourcesData =
  { cardIndex : Int
  , resourceAllocation : ResourceAllocation
  , verdict : ResourceAllocationVerdict
  }

type alias ChoseResourcesData =
  { cardIndex : Int
  , resourceAllocation : ResourceAllocation
  }

type alias ResourceAllocationVerdict =
  { extraResources : ResourceArray
  , missingResources : ResourceArray
  , missingGold : Int
  }

isVerdictOk : ResourceAllocationVerdict -> Bool
isVerdictOk rav =
  List.all identity
    [ List.all ((==) 0) rav.extraResources
    , List.all ((==) 0) rav.missingResources
    , rav.missingGold == 0
    ]

type alias ResourceAllocation = List (List Int)

type PlayerAction
  = PickCard Int
  | CancelCard
  | GetResource Int Int Int
  | Validate
  | Unvalidate