module Views.Lobby exposing (viewLobby)

import A_Model exposing (GameInfo, LobbyModel, NewGameData)
import B_Message exposing (Msg(..), NewGameMessage(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


viewLobby : LobbyModel -> Html Msg
viewLobby lobbyModel =
    div []
        [ input [ type_ "text", placeholder "Votre nom", value lobbyModel.playerName, onInput NewPlayerName ] []
        , h2 [] [ text "Liste des parties" ]
        , viewGameInfos lobbyModel.games
        , viewNewGameForm lobbyModel.newGameData
        ]


viewGameInfos : List GameInfo -> Html Msg
viewGameInfos gameInfos =
    let
        viewGameInfo g =
            p []
                [ text <| g.name ++ " (nombre maximum de joueurs: " ++ String.fromInt g.playerCount ++ ")"
                , button [ onClick (JoinGame g.name) ] [ text "Jouer!" ]
                ]
    in
    div [] (List.map viewGameInfo gameInfos)


viewNewGameForm : NewGameData -> Html Msg
viewNewGameForm ngd =
    let
        nameForm name =
            input [ type_ "text", placeholder "Nom de la partie", value name, onInput (GameName >> NewGame) ] []

        playerCountForm playerCount =
            input
                [ type_ "number"
                , placeholder (String.fromInt 3)
                , value (String.fromInt playerCount)
                , Html.Attributes.min "3"
                , Html.Attributes.max "7"
                , onInput (String.toInt >> Maybe.withDefault 3 >> PlayerCount >> NewGame)
                ]
                []
    in
    div []
        [ nameForm ngd.name
        , playerCountForm ngd.playerCount
        , button [ onClick (NewGame AddGame) ] [ text "Nouvelle partie!" ]
        ]
