module A_Model exposing (..)

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
  { gameName : String
  , playerName : String
  , playerId : Int
  , playerHand : Maybe (List Card)
  , play : Play
  , playerCount : Int
  , connectedPlayers : List String
  , game : Maybe Game
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
  { name : String
  , goldCost : Int
  , resourceCost : ResourceArray
  , effect : CardEffect
  , chainingTargets : List String
  , chainingSources : List String
  }

type alias ResourceArray = List Int

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