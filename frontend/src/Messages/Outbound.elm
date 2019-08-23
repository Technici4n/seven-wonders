module Messages.Outbound exposing (..)

import Json.Encode exposing (..)

-- MESSAGES

type FromPlayer
  = CreateGame String Int
  | Connect ConnectInfo

type alias ConnectInfo =
  { gameName : String
  , playerName : String
  }

-- ENCODERS

fromPlayer : FromPlayer -> Value
fromPlayer fp =
  case fp of
    CreateGame name playerCount ->
      object
        [ ( "CreateGame", createGame name playerCount ) ]
    Connect ci ->
      object
        [ ( "Connect", connectInfo ci ) ]

createGame : String -> Int -> Value
createGame name playerCount =
  list identity
    [ string name
    , int playerCount
    ]

connectInfo : ConnectInfo -> Value
connectInfo ci =
  object
    [ ( "game_name", string ci.gameName )
    , ( "player_name", string ci.playerName )
    ]