module F_Update exposing (update)

import A_Model exposing (GameModel, LobbyModel, Model(..), Play(..), RenderParameters, Textures)
import B_Message exposing (Msg(..), NewGameMessage(..))
import C_Data exposing (ConnectInfo, FromPlayer(..), ToPlayer(..))
import Data.Decode exposing (decodeToPlayer)
import Data.Encode exposing (encodeFromPlayer)
import Data.Font as Font
import Data.TextureAtlas as TextureAtlas
import Http
import Json.Decode as Decode exposing (decodeString)
import ListUtil as L
import Render.Image as Image
import Render.Text as Text
import Task
import Websocket exposing (send)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        noUpdate =
            ( model, Cmd.none )

        decodeWsMessage m f =
            let
                _ =
                    Debug.log "message" m
            in
            case decodeToPlayer m of
                Ok decodedMsg ->
                    f <| Debug.log "decoded message" decodedMsg

                Err e ->
                    noUpdate

        updateLobby lobbyMsg lobbyModel =
            case lobbyMsg of
                WsMessage m ->
                    decodeWsMessage m <|
                        \decodedMsg ->
                            case decodedMsg of
                                GameList list ->
                                    ( InLobby { lobbyModel | games = list }, Cmd.none )

                                ActiveGame playerInfo activeGameInfo ->
                                    updateActiveGame Nothing Nothing playerInfo activeGameInfo <| Cmd.batch [ loadRenderParameters, loadTextures ]

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

                PerformAction a ->
                    noUpdate

                RenderParametersLoaded rp ->
                    noUpdate

                TexturesLoaded t ->
                    noUpdate

        updateGame gameMsg gameModel =
            case gameMsg of
                WsMessage m ->
                    decodeWsMessage m <|
                        \decodedMsg ->
                            case decodedMsg of
                                GameList _ ->
                                    noUpdate

                                ActiveGame playerInfo activeGameInfo ->
                                    updateActiveGame gameModel.renderParameters gameModel.textures playerInfo activeGameInfo Cmd.none

                NewGame _ ->
                    noUpdate

                NewPlayerName _ ->
                    noUpdate

                JoinGame _ ->
                    noUpdate

                PerformAction action ->
                    ( model
                    , Action action
                        |> encodeFromPlayer
                        |> send
                    )

                RenderParametersLoaded maybeRp ->
                    case maybeRp of
                        Just rp ->
                            ( InGame { gameModel | renderParameters = Just rp }, Cmd.none )

                        Nothing ->
                            noUpdate

                TexturesLoaded maybeT ->
                    case maybeT of
                        Just t ->
                            ( InGame { gameModel | textures = Just t }, Cmd.none )

                        Nothing ->
                            noUpdate

        updateActiveGame renderParameters textures playerInfo activeGameInfo cmd =
            let
                playerId =
                    activeGameInfo.connectedPlayers
                        |> L.findIndex playerInfo.playerName
                        |> Maybe.withDefault -1
            in
            ( InGame
                { renderParameters = renderParameters
                , textures = textures
                , gameName = activeGameInfo.name
                , playerName = playerInfo.playerName
                , playerId = playerId
                , playerHand = playerInfo.cards
                , play = Maybe.withDefault NoAction playerInfo.play
                , playerCount = activeGameInfo.playerCount
                , connectedPlayers = activeGameInfo.connectedPlayers
                , game = activeGameInfo.game
                , shownPlayer = activeGameInfo.playerCount - 1
                }
            , cmd
            )
    in
    case model of
        InLobby lobbyModel ->
            updateLobby msg lobbyModel

        InGame gameModel ->
            updateGame msg gameModel


handleNewGameMessage : NewGameMessage -> LobbyModel -> ( Model, Cmd Msg )
handleNewGameMessage m lobbyModel =
    case m of
        GameName name ->
            ( InLobby
                { lobbyModel
                    | newGameData =
                        { name = name
                        , playerCount = lobbyModel.newGameData.playerCount
                        }
                }
            , Cmd.none
            )

        PlayerCount playerCount ->
            ( InLobby
                { lobbyModel
                    | newGameData =
                        { name = lobbyModel.newGameData.name
                        , playerCount = playerCount
                        }
                }
            , Cmd.none
            )

        AddGame ->
            let
                ngd =
                    lobbyModel.newGameData
            in
            ( InLobby lobbyModel
            , CreateGame ngd.name ngd.playerCount
                |> encodeFromPlayer
                |> send
            )


renderParametersDecoder : Decode.Decoder RenderParameters
renderParametersDecoder =
    Decode.map2 RenderParameters
        (Decode.field "textures" TextureAtlas.textureAtlasDecoder)
        (Decode.field "font" Font.fontDecoder)


loadRenderParameters : Cmd Msg
loadRenderParameters =
    Http.get
        { url = "/data.json"
        , expect = Http.expectJson (Result.toMaybe >> RenderParametersLoaded) renderParametersDecoder
        }


loadTextures : Cmd Msg
loadTextures =
    Task.map2 Textures
        Image.loadTexture
        Text.loadTexture
        |> Task.attempt (Result.toMaybe >> TexturesLoaded)
