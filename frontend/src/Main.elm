import Browser
import Html exposing (..)
import Html.Attributes exposing (type_, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode exposing (decodeString)
import Json.Encode exposing (encode)
import Messages.Inbound exposing (GameInfo, toPlayer, ToPlayer(..), Game)
import Messages.Outbound exposing (fromPlayer, FromPlayer(..), ConnectInfo)
import Websocket exposing (listen, send)

-- MAIN

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL

type Model
  = InLobby LobbyModel
  | InGame GameModel

type alias LobbyModel =
  { playerName : String
  , games : List GameInfo
  , newGameData : NewGameData
  }

type alias GameModel =
  { gameName : String
  , playerName : String
  , playerCount : Int
  , connectedPlayers : List String
  , game : Maybe Game
  }

-- Data for the "new game" form
type alias NewGameData =
  { name : String
  , playerCount : Int
  }

init : () -> (Model, Cmd Msg)
init _ =
  (InLobby { playerName = "", games = [], newGameData = { name = "", playerCount = 3 }}, Cmd.none)

-- UPDATE
-- TODO: seperate messages: WsMsg, LobbyMsg and GameMsg
type Msg
  -- Message from server via WebSockets
  = WsMessage String
  -- Lobby messages
  | NewGame NewGameMessage
  | NewPlayerName String
  | JoinGame String

type NewGameMessage
  = AddGame
  | GameName String
  | PlayerCount Int

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    noUpdate =
      ( model, Cmd.none )
    decodeWsMessage m f =
      let _ = Debug.log "message" m
      in
        case decodeString toPlayer m of
          Ok decodedMsg ->
            f decodedMsg
          Err _ ->
            noUpdate

    updateLobby lobbyMsg lobbyModel =
      case lobbyMsg of
        WsMessage m -> decodeWsMessage m <|
          \decodedMsg ->
            case decodedMsg of
              GameList list ->
                ( InLobby { lobbyModel | games = list }, Cmd.none )
              ActiveGame playerInfo activeGameInfo ->
                updateActiveGame playerInfo activeGameInfo
        NewGame m ->
          handleNewGameMessage m lobbyModel
        NewPlayerName name ->
          ( InLobby { lobbyModel | playerName = name }, Cmd.none )
        JoinGame gameName ->
          ( model
          , Connect (ConnectInfo gameName lobbyModel.playerName)
            |> fromPlayer
            |> encode 0
            |> send
          )

    updateGame gameMsg gameModel =
      case gameMsg of
        WsMessage m -> decodeWsMessage m <|
          \decodedMsg ->
            case decodedMsg of
              GameList _ ->
                noUpdate
              ActiveGame playerInfo activeGameInfo ->
                updateActiveGame playerInfo activeGameInfo
        NewGame _ ->
          noUpdate
        NewPlayerName _ ->
          noUpdate
        JoinGame _ ->
          noUpdate
        

    updateActiveGame playerInfo activeGameInfo =
      ( InGame (GameModel activeGameInfo.name playerInfo.playerName activeGameInfo.playerCount activeGameInfo.connectedPlayers activeGameInfo.game), Cmd.none )
  in
    case model of
      InLobby lobbyModel ->
        updateLobby msg lobbyModel
      InGame gameModel ->
        updateGame msg gameModel

handleNewGameMessage : NewGameMessage -> LobbyModel -> (Model, Cmd Msg)
handleNewGameMessage m lobbyModel =
  case m of
    GameName name ->
      ( InLobby
        { lobbyModel
        | newGameData =
          { name = name
          , playerCount = lobbyModel.newGameData.playerCount
          }
        }, Cmd.none )
    PlayerCount playerCount ->
      ( InLobby
        { lobbyModel
        | newGameData =
          { name = lobbyModel.newGameData.name
          , playerCount = playerCount
          }
        }, Cmd.none )
    AddGame ->
      let ngd = lobbyModel.newGameData
      in
        ( InLobby lobbyModel
        , CreateGame ngd.name ngd.playerCount
          |> fromPlayer
          |> encode 0
          |> send
        )

-- SUBSCRIPTIONS

subscriptions model =
  listen WsMessage

-- VIEW

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