module G_View exposing (view)

import A_Model exposing (GameInfo, GameModel, LobbyModel, Model(..), NewGameData)
import B_Message exposing (Msg(..), NewGameMessage(..))
import Html exposing (button, div, h2, h3, input, li, p, text, ul, Html)
import Html.Attributes exposing (placeholder, type_, value)
import Html.Events  exposing (onClick, onInput)
import Views.Game exposing (viewGame)
import Views.Lobby exposing (viewLobby)

view : Model -> Html Msg
view model =
  case model of
    InLobby lobbyModel ->
      viewLobby lobbyModel
    InGame gameModel ->
      viewGame gameModel