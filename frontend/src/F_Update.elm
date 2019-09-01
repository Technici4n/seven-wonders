module F_Update exposing (update)

import A_Model exposing (GameModel, LobbyModel, Model(..))
import B_Message exposing (Msg(..), NewGameMessage(..))
import C_Data exposing (ConnectInfo, FromPlayer(..), ToPlayer(..))
import Data.Decode exposing (decodeToPlayer)
import Data.Encode exposing (encodeFromPlayer)
import Json.Decode exposing (decodeString)
import Websocket exposing (send)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    noUpdate =
      ( model, Cmd.none )
    decodeWsMessage m f =
      let _ = Debug.log "message" m
      in
        case decodeToPlayer m of
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
            |> encodeFromPlayer
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
      ( InGame (GameModel activeGameInfo.name playerInfo.playerName playerInfo.cards activeGameInfo.playerCount activeGameInfo.connectedPlayers activeGameInfo.game), Cmd.none )
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
          |> encodeFromPlayer
          |> send
        )