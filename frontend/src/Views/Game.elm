module Views.Game exposing (viewGame)

import A_Model
    exposing
        ( Card
        , CardColor(..)
        , ChoosingResourcesData
        , ChoseResourcesData
        , Game
        , GameModel
        , Play(..)
        , PlayerAction(..)
        , PlayerData
        , RenderParameters
        , ResourceArray
        , emptyResourceArray
        , isVerdictOk
        )
import B_Message exposing (Msg(..))
import Html exposing (..)
import Html.Attributes exposing (class, disabled, height, id, style, width)
import Html.Events exposing (onClick)
import ListUtil as L
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import Rectangle exposing (Rectangle)
import Render
import Render.Image as Image
import Render.Text as Text
import Render.VertexList as VertexList exposing (VertexList)
import WebGL


viewGame : GameModel -> Html Msg
viewGame gameModel =
    let
        welcomeText =
            case gameModel.game of
                Just _ ->
                    "Game started ("

                Nothing ->
                    "Waiting for more players ("

        connectedPlayersCount =
            String.fromInt <| List.length <| gameModel.connectedPlayers

        maxPlayers =
            String.fromInt gameModel.playerCount

        viewGameStatus =
            p [] [ text (welcomeText ++ connectedPlayersCount ++ "/" ++ maxPlayers ++ ")") ]

        maybeViewActiveGame =
            let
                state =
                    Maybe.map3 ActiveGameState
                        gameModel.playerHand
                        gameModel.game
                        (Maybe.andThen (L.get gameModel.playerId) (Maybe.map .players gameModel.game))
            in
            case state of
                Just s ->
                    div []
                        [ viewActiveGame gameModel s
                        , viewScene gameModel s
                        ]

                Nothing ->
                    div [] []
    in
    div []
        [ h2 [] [ text ("Welcome to game " ++ gameModel.gameName) ]
        , viewGameStatus
        , viewConnectedPlayers gameModel.connectedPlayers
        , maybeViewActiveGame
        ]


nothing : Html Msg
nothing =
    div [] []


viewConnectedPlayers : List String -> Html Msg
viewConnectedPlayers connectedPlayers =
    div []
        [ h3 [] [ text "Joueurs connectés" ]
        , ul []
            (List.map
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
            , Just <| viewPlay_legacy gameModel state
            ]


viewPlay_legacy : GameModel -> ActiveGameState -> Html Msg
viewPlay_legacy gameModel state =
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


viewCards : List Card -> Html Msg
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
        addResourceType ( name, quantity ) resourceList =
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
                [ text "Jouer la carte "
                , i [] [ text card.name ]
                ]

        playerData =
            L.get gameModel.playerId state.game.players

        viewProduction resourceCosts production msg ra =
            let
                resourceButtons =
                    List.map3 ResourceAttributes resourceCosts resourceNames production
                        |> List.indexedMap
                            (\i attr -> ( i, attr ))
                        |> List.filter (\( i, attr ) -> attr.production > 0)
                        |> List.map
                            (\( i, attr ) ->
                                td []
                                    [ button
                                        [ onClick <| PerformAction <| msg (i + 1)
                                        , disabled <| ra == (i + 1)
                                        ]
                                        [ text (attr.name ++ " (-" ++ String.fromInt attr.cost ++ "g)") ]
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
                        :: resourceButtons
                    )
                ]

        viewPlayer resourceCosts productions playerName msg resourceAllocation =
            td [] <|
                List.concat
                    [ [ h4 [] [ text playerName ] ]
                    , resourceAllocation
                        |> List.map2 Tuple.pair productions
                        |> List.indexedMap
                            (\i ( production, ra ) -> viewProduction resourceCosts production (msg i) ra)
                    ]

        cancelButton =
            button [ onClick <| PerformAction <| CancelCard ] [ text "Jouer une autre carte" ]

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
                        0 ->
                            Nothing

                        i ->
                            Just <| "Il vous manque " ++ String.fromInt i ++ "or"
            in
            case isVerdictOk data.verdict of
                True ->
                    button [ onClick <| PerformAction <| Validate ] [ text "Valider!" ]

                False ->
                    [ missingResources
                    , extraResources
                    , missingGold
                    ]
                        |> List.filterMap identity
                        -- remove `Nothing`
                        |> List.map (\verdictExplanation -> p [] [ text verdictExplanation ])
                        -- give each message its own paragraph
                        |> List.append [ p [] [ text "Vous ne pouvez pas jouer cette carte" ] ]
                        -- add error message
                        |> div []

        -- put it all in a `div`
        validateAndCancel =
            div []
                [ div [] [ verdictInfo ]
                , div [] [ cancelButton ]
                ]
    in
    div []
        [ L.get data.cardIndex state.playerHand
            |> Maybe.map viewCard
            |> Maybe.withDefault nothing
        , validateAndCancel
        , List.map4 (\a b c s -> ( ( a, b, c ), s )) state.playerData.resourceCosts state.playerData.resourceProductions adjacentPlayerNames data.resourceAllocation
            |> List.indexedMap (\i ( ( c, p, n ), s ) -> viewPlayer c p n (GetResource i) s)
            |> (\x -> table [] [ tr [] x ])
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
        [ L.get data.cardIndex state.playerHand
            |> Maybe.map viewCard
            |> Maybe.withDefault nothing
        , cancelButton
        ]



-- WebGL drawings


viewScene : GameModel -> ActiveGameState -> Html Msg
viewScene gameModel ags =
    case Maybe.map2 Tuple.pair gameModel.renderParameters gameModel.textures of
        Just ( renderParameters, textures ) ->
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
                    , id "sceneCanvas"
                    ]

                entities =
                    [ viewPlayers renderParameters gameModel ags
                    , viewPlay renderParameters gameModel ags
                    --, viewHand renderParameters ags.playerHand
                    ]
            in
            div [ id "renderContainer", width 1600, height 900 ] <|
                [ WebGL.toHtmlWith webglParameters canvasAttributes <|
                    Render.toEntities textures <|
                        List.map Render.toPart <|
                            entities
                ]
                    ++ Render.toHtml (List.concat entities)

        Nothing ->
            text "No render :("


type CardColumn
    = Resources
    | Points
    | Trade
    | Military
    | Science
    | Guilds


cardColumn : Card -> CardColumn
cardColumn card =
    case card.color of
        Blue ->
            Points

        Brown ->
            Resources

        Gray ->
            Resources

        Green ->
            Science

        Purple ->
            Guilds

        Red ->
            Military

        Yellow ->
            Trade


columnWidth : CardColumn -> Float
columnWidth column =
    case column of
        Guilds ->
            3.2

        _ ->
            2.4


showBoard : RenderParameters -> Rectangle -> PlayerData -> List Render.Element
showBoard renderParameters target playerData =
    let
        columnInterspace =
            0.1

        getColumn column =
            { width = columnWidth column
            , cards =
                playerData.boardCards
                    |> List.filter (\c -> cardColumn c == column)
            }

        columns =
            [ Resources, Points, Trade, Military, Science, Guilds ]
                |> List.map getColumn
                |> List.filter (\c -> List.length c.cards > 0)

        drawColumn columnData xoffset =
            columnData.cards
                |> List.indexedMap
                    (\i card ->
                        Image.render renderParameters.atlas card.name
                            |> Render.imageToElement
                            |> Render.mapRectangle (Rectangle.translate ( xoffset, toFloat i ))
                    )

        accumulateColumns column ( xoffset, images ) =
            ( xoffset + column.width + columnInterspace
            , images ++ drawColumn column xoffset
            )

        columnImages =
            columns
                |> List.foldl accumulateColumns ( 0.0, [] )
                |> Tuple.second
                |> Render.mapRectangles (Rectangle.center target)
    in
    columnImages


viewPlayers : RenderParameters -> GameModel -> ActiveGameState -> List Render.Element
viewPlayers renderParameters gameModel ags =
    let
        mainBoard =
            Rectangle (8 / 9) (3 / 9) (4 / 9) (2 / 9)

        leftBoard =
            Rectangle (4 / 9) (2 / 9) (1 / 9) (6 / 9)

        rightBoard =
            Rectangle (4 / 9) (2 / 9) (11 / 9) (6 / 9)

        mainText =
            Rectangle (4 / 9) (0.3 / 9) (6 / 9) (5.2 / 9)

        centerText =
            Rectangle (4 / 9) (0.3 / 9) (6 / 9) (5.6 / 9)

        leftText =
            Rectangle (4 / 9) (0.3 / 9) (1 / 9) (5.6 / 9)

        rightText =
            Rectangle (4 / 9) (0.3 / 9) (11 / 9) (5.6 / 9)

        checkoutLeft =
            Rectangle (1 / 9) (1 / 9) (0.5 / 9) (6.5 / 9)

        checkoutRight =
            Rectangle (1 / 9) (1 / 9) (14.5 / 9) (6.5 / 9)

        shownPlayerRectangle =
            Rectangle (12 / 9) (0.3 / 9) (2 / 9) (8.5 / 9)

        drawCheckout str target msg =
            Text.render renderParameters.font (vec3 0.0 0.0 0.0) str
                |> Render.textToElement
                |> Render.onClick msg
                |> (\x -> Render.mapRectangles (Rectangle.center target) [ x ])

        playerExtraText position =
            let
                rpos =
                    modBy gameModel.playerCount (position - gameModel.playerId)
            in
            if rpos == 0 then
                " (vous)"
            else if rpos == 1 then
                " (votre voisin de droite)"
            else if rpos == gameModel.playerCount - 1 then
                " (votre voisin de gauche)"
            else
                " (vous ne pouvez pas interagir)"

        showText target name =
            Text.render renderParameters.font (vec3 0.0 0.0 0.0) name
            |> Render.textToElement
            |> (\x -> Render.mapRectangles (Rectangle.center target) [ x ])
        
        showCenterText =
            showText centerText ">> Recentrer sur moi <<"
            |> List.map (Render.onClick CenterShownPlayer)

        drawPlayer position ( name, playerData ) =
            let
                mod = modBy gameModel.playerCount
            in
            if position == gameModel.shownPlayer then
                showBoard renderParameters mainBoard playerData
                ++ showText mainText (name ++ playerExtraText position)
                ++
                    if position == gameModel.playerId then
                        []
                    else
                        showCenterText
            else if position == mod (gameModel.shownPlayer+1) then
                showBoard renderParameters rightBoard playerData
                ++ showText rightText (name ++ playerExtraText position)
            else if mod (position+1) == gameModel.shownPlayer then
                showBoard renderParameters leftBoard playerData
                ++ showText leftText (name ++ playerExtraText position)
            else
                []
    in
    List.concat
        [ ags.game.players
            |> List.map2 Tuple.pair gameModel.connectedPlayers
            |> List.indexedMap drawPlayer
            |> List.concat
        , drawCheckout "GAUCHE" checkoutLeft (ChangeShownPlayer -1)
        , drawCheckout "DROITE" checkoutRight (ChangeShownPlayer 1)
        ]

viewPlay : RenderParameters -> GameModel -> ActiveGameState -> List Render.Element
viewPlay renderParameters gameModel ags =
    case gameModel.play of
        NoAction ->
            viewHand renderParameters ags.playerHand
        ChoosingResources data ->
            viewPlayCard renderParameters gameModel ags data
        ChoseResources { cardIndex, resourceAllocation } ->
            []

viewHand : RenderParameters -> List Card -> List Render.Element
viewHand renderParameters cards =
    let
        cardInterspace =
            0.1

        handRectangle =
            Rectangle (16 / 9) (1 / 9) 0.0 0.0

        textRectangle =
            Rectangle (16 / 9) 0.05 0.0 (1.1 / 9)

        drawCard xoffset name i =
            Image.render renderParameters.atlas name
                |> Render.imageToElement
                |> Render.onClick (PerformAction (PickCard i))
                |> Render.mapRectangle (Rectangle.translate ( xoffset, 0.0 ))

        accumulateCards card ( xoffset, triangles, i ) =
            ( xoffset + columnWidth (cardColumn card) + cardInterspace
            , triangles ++ [ drawCard xoffset card.name i ]
            , i + 1
            )

        cardElements =
            List.foldl accumulateCards ( 0, [], 0 ) cards
                |> \(a, b, c) -> b
                |> Render.mapRectangles (Rectangle.center handRectangle)

        handText =
            Text.render renderParameters.font (vec3 0.0 0.0 0.0) "VOTRE MAIN"
                |> Render.textToElement
                |> (\x ->
                        [ x ]
                            |> Render.mapRectangles (Rectangle.center textRectangle)
                   )
    in
    handText ++ cardElements

viewPlayCard : RenderParameters -> GameModel -> ActiveGameState -> ChoosingResourcesData -> List Render.Element
viewPlayCard renderParameters gameModel ags data =
    let
        textRect =
            Rectangle (2 / 9) (1 / 9) (7 / 9) (1 / 9)

        cardRect =
            Rectangle (2 / 9) (1 / 9) (9 / 9) (1 / 9)

        questionRect =
            Rectangle (0.25 / 9) (0.3 / 9) (11.05 / 9) (1.35 / 9)

        cancelRect =
            Rectangle (1 / 9) (1 / 9) (11.5 / 9) (1 / 9)

        cardAndTextRect =
            Rectangle (5 / 9) (1 / 9) (5.5 / 9) (1 / 9)

        viewCardAndText selectedCard =
            [ Render.text renderParameters.font (vec3 0.0 0.0 0.0) "Jouer la carte " textRect
            , Render.image renderParameters.atlas selectedCard.name cardRect
            , Render.text renderParameters.font (vec3 0.0 0.0 0.0) "?" questionRect
            , Render.text renderParameters.font (vec3 0.0 0.0 0.0) "Annuler!" cancelRect
                |> List.map (Render.onClick (PerformAction (CancelCard)))
            ]
            |> List.concat
            |> Render.mapRectangles (Rectangle.center cardAndTextRect)
    in
    L.get data.cardIndex ags.playerHand
        |> Maybe.map viewCardAndText
        |> Maybe.withDefault []
