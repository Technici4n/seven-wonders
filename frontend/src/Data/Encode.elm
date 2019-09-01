module Data.Encode exposing (encodeFromPlayer)

import C_Data exposing (ConnectInfo, FromPlayer(..))
import Json.Encode exposing (encode, int, list, object, string, Value)

encodeFromPlayer : FromPlayer -> String
encodeFromPlayer fp =
  fp
  |> fromPlayer
  |> encode 0

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