module Views.Game exposing (viewGame)

import A_Model exposing (isVerdictOk, Card, ChoseResourcesData, ChoosingResourcesData, Game, GameModel, Play(..), PlayerAction(..), PlayerData)
import B_Message exposing (Msg(..))
import Html exposing (..)
import Html.Events exposing (onClick)
import ListUtil as L

viewGame : GameModel -> Html Msg
viewGame gameModel =
  let
    welcomeText = case gameModel.game of
      Just _ -> "Game started ("
      Nothing -> "Waiting for more players ("
    connectedPlayersCount =
      String.fromInt <| List.length <| gameModel.connectedPlayers
    maxPlayers =
      String.fromInt gameModel.playerCount
    viewGameStatus =
      p [] [ text (welcomeText ++ connectedPlayersCount ++ "/" ++ maxPlayers ++ ")" ) ]
    maybeViewActiveGame =
      let
        state =
          Maybe.map3 ActiveGameState
            gameModel.playerHand
            gameModel.game
            (Maybe.andThen (L.get gameModel.playerId) (Maybe.map .players gameModel.game))
      in
        case state of
          Just s -> viewActiveGame gameModel s
          Nothing -> div [] []

      
  in
    div []
      [ h2 [] [ text ("Welcome to game " ++ gameModel.gameName) ]
      , viewGameStatus
      , viewConnectedPlayers gameModel.connectedPlayers
      , maybeViewActiveGame
      ]

nothing : Html Msg
nothing = div [] []

viewConnectedPlayers : List String -> Html Msg
viewConnectedPlayers connectedPlayers =
  div []
  [ h3 [] [ text "Joueurs connectés" ]
  , ul [] (List.map
      (\player -> li [] [ text player ])
      connectedPlayers
    )
  ]

type alias ActiveGameState =
  { playerHand : List Card
  , game : Game
  , playerData : PlayerData
  }

viewActiveGame : GameModel -> ActiveGameState -> Html Msg
viewActiveGame gameModel state =
  div [] <|
    List.filterMap identity
      [ Maybe.map viewBoard <| L.get gameModel.playerId state.game.players
      , Just <| viewPlay gameModel state
      ]

viewPlay : GameModel -> ActiveGameState -> Html Msg
viewPlay gameModel state =
  case gameModel.play of
    NoAction ->
      viewCards state.playerHand
    ChoosingResources data ->
      viewResourceChoice gameModel state data
    ChoseResources data ->
      viewTurnStatus gameModel state data

viewBoard : PlayerData -> Html Msg
viewBoard playerData =
  div []
    [ h3 [] [ text "Votre plateau" ]
    , playerData.boardCards
      |> List.map (\c -> p [] [ text c.name ])
      |> div []
    ]

viewCards : (List Card) -> Html Msg
viewCards cards =
  let
    viewCard i card =
      p []
        [ text card.name
        , button [ onClick <| PerformAction <| PickCard i ] [ text "Jouer!" ]
        ]
  in
    div []
      [ h3 [] [ text "Votre main" ]
      , cards
        |> List.indexedMap viewCard
        |> div []
      ]

resourceNames : List String
resourceNames =
  [ "Argile"
  , "Bois"
  , "Minerai"
  , "Pierre"
  , "Verre"
  , "Papyrus"
  , "Tissu"
  ]

adjacentPlayerNames : List String
adjacentPlayerNames =
  [ "Joueur de gauche"
  , "Vous"
  , "Joueur de droite"
  ]

type alias ResourceAttributes =
  { cost : Int
  , name : String
  , production : Int
  }

viewResourceChoice : GameModel -> ActiveGameState -> ChoosingResourcesData -> Html Msg
viewResourceChoice gameModel state data =
  let
    viewCard card =
      h3 []
        [ text ( "Jouer la carte " )
        , i [] [ text card.name ]
        ]
    playerData =
      L.get (gameModel.playerId) state.game.players
    viewProduction resourceCosts production msg =
      let
        resourceButtons =
          List.map3 ResourceAttributes resourceCosts resourceNames production
          |> List.indexedMap
            (\i attr -> (i, attr))
          |> List.filter (\(i, attr) -> attr.production > 0)
          |> List.map
            (\(i, attr) ->
              td []
                [ button
                  [ onClick <| PerformAction <| msg (i+1)]
                  [ text (attr.name ++ " (-" ++ (String.fromInt attr.cost) ++ "g)") ]
                ]
            )
      in
        table []
          [ tr [] <|
              (td []
                [ button
                  [ onClick <| PerformAction <| msg 0 ]
                  [ text "Rien" ]
                ]
              :: resourceButtons)
          ]
    viewPlayer resourceCosts productions playerName msg =
      td [] <|
        List.concat
          [[ h4 [] [ text playerName ] ]
          , productions
            |> List.indexedMap
              (\i production -> viewProduction resourceCosts production (msg i))
          ]
    cancelButton = button [ onClick <| PerformAction <| CancelCard ] [ text "Jouer une autre carte" ]
    verdictInfo =
      case isVerdictOk data.verdict of
        True ->
          button [ onClick <| PerformAction <| Validate ] [ text "Valider!" ]
        False ->
          p [] [ text "Vous ne pouvez pas jouer cette carte" ]
    cancelAndConfirm =
      div []
        [ div [] [ verdictInfo ]
        , div [] [ cancelButton ]
        ]
  in
    div []
    [ L.get (data.cardIndex) state.playerHand
      |> Maybe.map viewCard
      |> Maybe.withDefault nothing
    , cancelAndConfirm
    , List.map3 (\a b c -> (a, b, c)) state.playerData.resourceCosts state.playerData.resourceProductions adjacentPlayerNames
      |> List.indexedMap (\i (c, p, n) -> viewPlayer c p n (GetResource i))
      |> \x -> table [] [ tr [] x ]
    ]

viewTurnStatus : GameModel -> ActiveGameState -> ChoseResourcesData -> Html Msg
viewTurnStatus gameModel state data =
  let
    viewCard card =
      h3 []
        [ text "La carte "
        , i [] [ text card.name ]
        , text " va être jouée"
        ]
    cancelButton =
      button [ onClick <| PerformAction <| Unvalidate ] [ text "Annuler" ]
  in
    div []
    [ L.get (data.cardIndex) state.playerHand
      |> Maybe.map viewCard
      |> Maybe.withDefault nothing
    , cancelButton
    ]