module Views.Game exposing (viewGame)

import A_Model exposing
  ( emptyResourceArray
  , isVerdictOk
  , Card
  , CardColor(..)
  , ChoseResourcesData
  , ChoosingResourcesData
  , Game
  , GameModel
  , Play(..)
  , PlayerAction(..)
  , PlayerData
  , RenderParameters
  , ResourceArray)
import B_Message exposing (Msg(..))
import Html exposing (..)
import Html.Attributes exposing (disabled, height, style, width)
import Html.Events exposing (onClick)
import ListUtil as L
import Math.Matrix4 as Mat4 exposing (Mat4)
import Render.Image as Image
import Render.VertexList as VertexList exposing (VertexList)
import Render exposing (ScenePart)
import WebGL

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
          Just s -> div [] 
            [ viewActiveGame gameModel s
            , viewScene gameModel s
            ]
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

individualResourceNames : ResourceArray -> List String
individualResourceNames resourceArray =
  let
    addResourceType (name, quantity) resourceList =
      name
      |> List.repeat quantity
      |> List.append resourceList
  in
    resourceArray
    |> List.map2 Tuple.pair resourceNames
    |> List.foldl addResourceType []

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
    viewProduction resourceCosts production msg ra =
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
                  [ onClick <| PerformAction <| msg (i+1)
                  , disabled <| ra == (i+1)
                  ]
                  [ text (attr.name ++ " (-" ++ (String.fromInt attr.cost) ++ "g)") ]
                ]
            )
      in
        table []
          [ tr [] <|
              (td []
                [ button
                  [ onClick <| PerformAction <| msg 0
                  , disabled <| ra == 0
                  ]
                  [ text "Rien" ]
                ]
              :: resourceButtons)
          ]
    viewPlayer resourceCosts productions playerName msg resourceAllocation =
      td [] <|
        List.concat
          [[ h4 [] [ text playerName ] ]
          , resourceAllocation
            |> List.map2 Tuple.pair productions
            |> List.indexedMap
              (\i (production, ra) -> viewProduction resourceCosts production (msg i) ra)
          ]
    cancelButton = button [ onClick <| PerformAction <| CancelCard ] [ text "Jouer une autre carte" ]
    verdictInfo =
      let
        missingResources =
          if data.verdict.missingResources == emptyResourceArray then
            Nothing
          else
            Just <| "Il manque ces ressources: " ++ String.join " " (individualResourceNames data.verdict.missingResources)
        extraResources =
          if data.verdict.extraResources == emptyResourceArray then
            Nothing
          else
            Just <| "Ces ressources sont en trop: " ++ String.join " " (individualResourceNames data.verdict.extraResources)
        missingGold =
          case data.verdict.missingGold of
            0 -> Nothing
            i -> Just <| "Il vous manque " ++ (String.fromInt i) ++ "or"
      in case isVerdictOk data.verdict of
        True ->
          button [ onClick <| PerformAction <| Validate ] [ text "Valider!" ]
        False ->
          [ missingResources
          , extraResources
          , missingGold
          ]
          |> List.filterMap identity -- remove `Nothing`
          |> List.map (\verdictExplanation -> p [] [ text verdictExplanation ]) -- give each message its own paragraph
          |> List.append [p [] [ text "Vous ne pouvez pas jouer cette carte" ]] -- add error message
          |> div [] -- put it all in a `div`
    validateAndCancel =
      div []
        [ div [] [ verdictInfo ]
        , div [] [ cancelButton ]
        ]
  in
    div []
      [ L.get (data.cardIndex) state.playerHand
        |> Maybe.map viewCard
        |> Maybe.withDefault nothing
      , validateAndCancel
      , List.map4 (\a b c s -> ((a, b, c), s)) state.playerData.resourceCosts state.playerData.resourceProductions adjacentPlayerNames data.resourceAllocation
        |> List.indexedMap (\i ((c, p, n), s) -> viewPlayer c p n (GetResource i) s)
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

type CardGroup
  = BrownGray -- Brown or gray
  | BlueRedYellow
  | GreenPurple

groupFromColor : CardColor -> CardGroup
groupFromColor color =
  case color of
    Blue -> BlueRedYellow
    Brown -> BrownGray
    Gray -> BrownGray
    Green -> GreenPurple
    Purple -> GreenPurple
    Red -> BlueRedYellow
    Yellow -> BlueRedYellow

-- WebGL drawings
viewScene : GameModel -> ActiveGameState -> Html Msg
viewScene gameModel ags =
  case Maybe.map2 Tuple.pair gameModel.renderParameters gameModel.textures of
    Just (renderParameters, textures) ->
      let
        webglParameters =
          [ WebGL.alpha True
          , WebGL.depth 1
          , WebGL.clearColor 0.6 0.6 0.6 1.0
          , WebGL.antialias
          ]
        canvasAttributes =
          [ width 1600
          , height 900
          , style "display" "block"
          ]
      in
        WebGL.toHtmlWith webglParameters canvasAttributes <|
          Render.toEntities textures <| Debug.log "triangles" <|
            viewHand renderParameters ags.playerHand
            :: viewPlayers renderParameters gameModel ags
    Nothing -> text "No render :("

-- Render PlayerData to a 1x1 square
viewPlayerData : RenderParameters -> PlayerData -> ScenePart
viewPlayerData renderParameters playerData =
  let
    -- unit: card height is 1.0
    firstColumnWidth = 3.2
    otherColumnWidth = 2.4
    columnInterspace = 0.5
    horizontalMargin = columnInterspace / 2.0
    totalWidth = 2 * horizontalMargin + 2 * columnInterspace + firstColumnWidth + 2 * otherColumnWidth
    cardHeight = 1.0
    cardInterspace = 0.0
    drawCard group position name =
      let
        unscaledHorizontalOffset =
          case group of
            GreenPurple -> horizontalMargin
            BlueRedYellow -> horizontalMargin + firstColumnWidth + columnInterspace
            BrownGray -> horizontalMargin + firstColumnWidth + 2*columnInterspace + otherColumnWidth
        verticalOffset =
          1.0 - ((position + 1) * cardHeight + position * cardInterspace) / totalWidth
        scalingFactor = 1.0 / totalWidth
        scale = Mat4.makeScale3 scalingFactor scalingFactor scalingFactor
        translate = Mat4.makeTranslate3 (unscaledHorizontalOffset / totalWidth) verticalOffset 0.0
        transformationMatrix = Mat4.mul translate scale
      in
        Image.render renderParameters.atlas name
        |> Debug.log "rendered image"
        |> VertexList.transformPosition transformationMatrix
    drawCardGroup group =
      playerData.boardCards
      |> List.filter (\c -> groupFromColor c.color == group)
      |> List.indexedMap (\i c -> drawCard group (toFloat i) c.name)
      |> List.concat
  in
    { images =
        List.concat
          [ drawCardGroup GreenPurple
          , drawCardGroup BlueRedYellow
          , drawCardGroup BrownGray
          ]
    , text = []
    }

viewPlayers : RenderParameters -> GameModel -> ActiveGameState -> List ScenePart
viewPlayers renderParameters gameModel ags =
  let
    boardSide = 4/9
    screenWidth = 16/9
    scaleBoard = Mat4.makeScale3 boardSide boardSide boardSide
    drawUpperPlayer position playerData =
      let
        translate = Mat4.makeTranslate3 (toFloat position * boardSide) (1.0 - boardSide) 0.0
        transformationMatrix = Mat4.mul translate scaleBoard
      in
        viewPlayerData renderParameters playerData
        |> Render.transformPosition transformationMatrix
    drawLeftPlayer playerData =
      viewPlayerData renderParameters playerData
      |> Render.transformPosition scaleBoard
    drawRightPlayer playerData =
      viewPlayerData renderParameters playerData
      |> Render.transformPosition (Mat4.mul (Mat4.makeTranslate3 (screenWidth - boardSide) 0.0 0.0) scaleBoard)
    drawCurrentPlayer playerData =
      viewPlayerData renderParameters playerData
      |> Render.transformPosition (Mat4.mul (Mat4.makeTranslate3 (screenWidth - 2*boardSide) 0.0 0.0) scaleBoard)
    drawPlayer position playerData =
      let
        relativePosition = modBy gameModel.playerCount (position - gameModel.playerId)
        drawFunction =
          if relativePosition == 0 then drawCurrentPlayer
          else if relativePosition == 1 then drawRightPlayer
          else if relativePosition == gameModel.playerCount-1 then drawLeftPlayer
          else drawUpperPlayer (5 - relativePosition)
      in
        drawFunction playerData
  in
    ags.game.players
    |> List.indexedMap drawPlayer

viewHand : RenderParameters -> List Card -> ScenePart
viewHand renderParameters cards =
  let
    maxCardWidth = 3.2
    cardWidth = 3.9/9
    cardHeight = cardWidth * (1 / maxCardWidth)
    cardPosition = 4.1 / 9
    scale = Mat4.makeScale3 cardHeight cardHeight cardHeight
    translate i = Mat4.makeTranslate3 cardPosition (toFloat i * cardHeight) 0.0
    transformationMatrix i = Mat4.mul (translate i) scale
    transform i card =
      card
      |> VertexList.transformPosition (transformationMatrix i)
  in
    { images =
        cards
        |> List.map .name
        |> List.map (Image.render renderParameters.atlas)
        |> List.indexedMap transform
        |> List.concat
    , text = []
    }

