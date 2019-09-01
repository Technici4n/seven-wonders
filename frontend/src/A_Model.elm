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
  , playerHand : Maybe (List Card)
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

type alias ResourceArray = List Int

type CardEffect
  = Resources ResourceArray
  | Points Int
  | RawMaterialsCost Int
  | ManufacturedProductsCost
  | Shields Int
  | Science Int
