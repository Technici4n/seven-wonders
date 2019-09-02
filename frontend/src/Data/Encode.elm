module Data.Encode exposing (encodeFromPlayer)

import A_Model exposing (PlayerAction(..))
import C_Data exposing (ConnectInfo, FromPlayer(..))
import Json.Encode exposing (encode, int, list, null, object, string, Value)

encodeFromPlayer : FromPlayer -> String
encodeFromPlayer fp =
  fp
  |> fromPlayer
  |> encode 0

field : String -> Value -> Value
field name data =
  object
    [ ( name, data ) ]

fromPlayer : FromPlayer -> Value
fromPlayer fp =
  case fp of
    CreateGame name playerCount ->
      field "CreateGame" (createGame name playerCount)
    Connect ci ->
      field "Connect"  (connectInfo ci)
    Action a ->
      field "Action" (action a)

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

action : PlayerAction -> Value
action a =
  case a of
    PickCard i ->
      field "PickCard" (int i)
    CancelCard ->
      field "CancelCard" null
    GetResource x y z ->
      field "GetResource" (list int [x, y, z])
    Validate ->
      field "Validate" null
    Unvalidate ->
      field "Unvalidate" null