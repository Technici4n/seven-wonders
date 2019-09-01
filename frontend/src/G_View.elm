module G_View exposing (view)

import A_Model exposing (GameInfo, GameModel, LobbyModel, Model(..), NewGameData)
import B_Message exposing (Msg(..), NewGameMessage(..))
import Html exposing (button, div, h2, h3, input, li, p, text, ul, Html)
import Html.Attributes exposing (placeholder, type_, value)
import Html.Events  exposing (onClick, onInput)

view : Model -> Html Msg
view model =
  case model of
    InLobby lobbyModel ->
      viewLobby lobbyModel
    InGame gameModel ->
      viewGame gameModel

viewLobby : LobbyModel -> Html Msg
viewLobby lobbyModel =
  div []
    [ input [ type_ "text", placeholder "Votre nom", value lobbyModel.playerName, onInput NewPlayerName ] []
    , h2 [] [ text "Liste des parties" ]
    , viewGameInfos lobbyModel.games
    , viewNewGameForm lobbyModel.newGameData
    ]

viewGame : GameModel -> Html Msg
viewGame gameModel =
  let
    welcomeText = case gameModel.game of
      Just _ -> "Game started ("
      Nothing -> "Waiting for more players ("
  in
    div []
      [ h2 [] [ text ("Welcome to game " ++ gameModel.gameName) ]
      , p [] [ text (welcomeText ++ (String.fromInt <| List.length <| gameModel.connectedPlayers) ++ "/" ++ (String.fromInt gameModel.playerCount) ++ ")" ) ]
      , viewConnectedPlayers gameModel.connectedPlayers
      ]

viewGameInfos : List GameInfo -> Html Msg
viewGameInfos g =
  div [] (List.map viewGameInfo g)

viewGameInfo : GameInfo -> Html Msg
viewGameInfo g =
  p []
    [ text <| g.name ++ " (nombre maximum de joueurs: " ++ (String.fromInt g.playerCount) ++ ")"
    , button [ onClick (JoinGame g.name) ] [ text "Jouer!" ]
    ]

viewNewGameForm : NewGameData -> Html Msg
viewNewGameForm ngd =
  let
    nameForm name = input [ type_ "text", placeholder "Nom de la partie", value name, onInput (GameName >> NewGame) ] []
    playerCountForm playerCount = input
      [ type_ "number"
      , placeholder (String.fromInt 3)
      , value (String.fromInt playerCount)
      , Html.Attributes.min "3"
      , Html.Attributes.max "7"
      , onInput (String.toInt >> Maybe.withDefault 3 >> PlayerCount >> NewGame)
      ] []
  in
    div []
      [ nameForm ngd.name
      , playerCountForm ngd.playerCount
      , button [ onClick (NewGame AddGame) ] [ text "Nouvelle partie!" ]
      ]
  
viewConnectedPlayers : List String -> Html Msg
viewConnectedPlayers connectedPlayers =
  div []
  [ h3 [] [ text "Joueurs connectés" ]
  , ul [] (List.map
      (\player -> li [] [ text player ])
      connectedPlayers
    )
  ]