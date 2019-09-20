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
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.Image as Image
import Render.Text as Text
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
            [ viewHand renderParameters ags.playerHand
            , Render.mergeParts <| viewPlayers renderParameters gameModel ags
            ]
    Nothing -> text "No render :("

type CardColumn
  = Resources
  | Points
  | Trade
  | Military
  | Science
  | Guilds

colorToColumn : CardColor -> CardColumn
colorToColumn color =
  case color of
    Blue -> Points
    Brown -> Resources
    Gray -> Resources
    Green -> Science
    Purple -> Guilds
    Red -> Military
    Yellow -> Trade

columnWidth : CardColumn -> Float
columnWidth column =
  case column of
    Guilds -> 3.2
    _ -> 2.4

type alias ColumnData =
  { width : Float
  , cards : List Card
  }

viewPlayerData : RenderParameters -> PlayerData -> ScenePart
viewPlayerData renderParameters playerData =
  let
    boardWidth = 4.0
    boardHeight = 1.0
    columnInterspace = 0.1
    getColumn column =
      { width = columnWidth column
      , cards =
          playerData.boardCards
          |> List.filter (\c -> colorToColumn c.color == column)
      }
    columns =
      [Resources, Points, Trade, Military, Science, Guilds]
      |> List.map getColumn
      |> List.filter (\c -> List.length c.cards > 0)
    totalWidth =
      (List.map .width >> List.sum) columns + columnInterspace * (toFloat (List.length columns) - 1) + 0.0000001
    cardHeight columnData =
      boardHeight * boardWidth / totalWidth
    columnHeight columnData =
      cardHeight columnData * toFloat (List.length columnData.cards)
    totalHeight =
      columns
      |> List.map columnHeight
      |> List.maximum
      |> Maybe.withDefault 1.0
    heightRatio = boardHeight / totalHeight
    newWidth = heightRatio * boardWidth
    drawColumn columnData xoffset =
      let
        height = cardHeight columnData
        drawCard position name =
          let
            scale = Mat4.makeScale3 height height height
            translate = Mat4.makeTranslate3 (xoffset / totalWidth * boardWidth) (toFloat position * height) 0.0
            transform = Mat4.mul translate scale
          in
            { images =
                Image.render renderParameters.atlas name
                |> VertexList.transformPosition transform
            , text = []
            }
      in
        columnData.cards
        |> List.map .name
        |> List.indexedMap drawCard
    accumulateColumns column { xoffset, sceneParts } =
      { xoffset = xoffset + column.width + columnInterspace
      , sceneParts = sceneParts ++ drawColumn column xoffset
      }
    renderedBoard =
      List.foldl accumulateColumns { xoffset = 0.0, sceneParts = [] } columns
      |> .sceneParts
      |> Render.mergeParts
  in
    if totalHeight > boardHeight then
      renderedBoard
      |> Render.transformPosition (Mat4.mul (Mat4.makeTranslate3 ((boardWidth - newWidth)/2) 0.0 0.0) (Mat4.makeScale3 heightRatio heightRatio heightRatio))
    else
      renderedBoard

viewPlayers : RenderParameters -> GameModel -> ActiveGameState -> List ScenePart
viewPlayers renderParameters gameModel ags =
  let
    screenHeight = 1.0
    screenWidth = 16/9
    currentPlayerBoardWidth = 12/9
    currentPlayerBoardHeight = 3/9
    currentPlayerHeight = 5/9
    translateCurrentPlayerBoard = Mat4.makeTranslate3 ((screenWidth - currentPlayerBoardWidth) / 2) (2/9)  0.0
    scaleCurrentPlayerBoard = Mat4.makeScale3 currentPlayerBoardHeight currentPlayerBoardHeight currentPlayerBoardHeight
    drawCurrentPlayer playerData =
      viewPlayerData renderParameters playerData
      |> Render.transformPosition (Mat4.mul translateCurrentPlayerBoard scaleCurrentPlayerBoard)
    shownPlayerBoardWidth = 12/9
    shownPlayerBoardHeight = 3/9
    shownPlayerPosition = 5.5/9
    translateShownPlayer = Mat4.makeTranslate3 ((screenWidth - shownPlayerBoardWidth) / 2) shownPlayerPosition 0.0
    scaleShownPlayer = Mat4.makeScale3 shownPlayerBoardHeight shownPlayerBoardHeight shownPlayerBoardHeight
    drawShownPlayer playerData =
      viewPlayerData renderParameters playerData
      |> Render.transformPosition (Mat4.mul translateShownPlayer scaleShownPlayer)
    drawPlayer position =
      let
        relativePosition = modBy gameModel.playerCount (position - gameModel.playerId)
        drawFunction =
          if relativePosition == 0 then drawCurrentPlayer >> Just
          else if relativePosition == gameModel.shownPlayer then drawShownPlayer >> Just
          else always Nothing
      in
        drawFunction
  in
    ags.game.players
    |> List.indexedMap drawPlayer
    |> List.filterMap identity

viewHand : RenderParameters -> List Card -> ScenePart
viewHand renderParameters cards =
  let
    cardInterspace = 0.1
    cardWidth = .color >> colorToColumn >> columnWidth
    handWidth =
      cardInterspace * toFloat (List.length cards - 1) +
      (cards
      |> List.map cardWidth
      |> List.sum)
    handHeight = 0.1
    handSpace = 16/9
    actualHandWidth = handWidth * handHeight
    drawCard xoffset name =
      Image.render renderParameters.atlas name
      |> VertexList.transformPosition (Mat4.makeTranslate3 xoffset 0.0 0.0)
    accumulateCards card (xoffset, images) =
      ( xoffset + cardInterspace + cardWidth card
      , images ++ drawCard xoffset card.name
      )
    translate = Mat4.makeTranslate3 ((handSpace - actualHandWidth) / 2) 0.0 0.0
    scale = Mat4.makeScale3 handHeight handHeight handHeight
    transform = Mat4.mul translate scale
    handText =
      Text.render renderParameters.font (vec3 0.0 0.0 0.0) "VOTRE MAIN"
      |> Debug.log "handText"
      |> VertexList.transformPosition (Mat4.mul (Mat4.makeTranslate3 (6.5/9) (1.1/9) 0.01) (Mat4.makeScale3 0.05 0.05 0.05))
  in
    { images =
        cards
        |> List.foldl accumulateCards (0.0, [])
        |> Tuple.second
        |> VertexList.transformPosition transform
    , text = handText
    }
