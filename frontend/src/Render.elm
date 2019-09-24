module Render exposing
    ( Element
    , Part
    , Primitive
    , imageToElement
    , mapRectangle
    , mapRectangles
    , onClick
    , textToElement
    , toEntities
    , toHtml
    , toPart
    , withHtml
    , withZindex
    )

import A_Model exposing (Textures)
import B_Message exposing (Msg)
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Events
import Math.Matrix4 as Mat4 exposing (Mat4)
import Rectangle exposing (Rectangle)
import Render.Image as Image
import Render.Text as Text
import Render.VertexList as VertexList exposing (VertexList)
import WebGL
import WebGL.Settings
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest


type alias Part =
    { images : VertexList Image.Vertex
    , text : VertexList Text.Vertex
    }


type Primitive
    = Images (VertexList Image.Vertex)
    | Text (VertexList Text.Vertex)


type alias Element =
    { primitive : Primitive
    , sourceRect : Rectangle
    , targetRect : Rectangle
    , html : List (Html Msg)
    , zindex : Float
    }


imageToElement : ( VertexList Image.Vertex, Rectangle ) -> Element
imageToElement ( vertices, rect ) =
    { primitive = Images vertices
    , sourceRect = rect
    , targetRect = rect
    , html = []
    , zindex = 0
    }


textToElement : ( VertexList Text.Vertex, Rectangle ) -> Element
textToElement ( vertices, rect ) =
    { primitive = Text vertices
    , sourceRect = rect
    , targetRect = rect
    , html = []
    , zindex = 0
    }


withHtml : List (Html Msg) -> Element -> Element
withHtml html element =
    { element | html = html }


withZindex : Float -> Element -> Element
withZindex z element =
    { element | zindex = z }


onClick : Msg -> Element -> Element
onClick message =
    withHtml [ Html.button [ Html.Events.onClick message, class "fill-parent" ] [ Html.text "button" ] ]


mapRectangle : (Rectangle -> Rectangle) -> Element -> Element
mapRectangle f input =
    { input | targetRect = f input.targetRect }


mapRectangles : (List Rectangle -> List Rectangle) -> List Element -> List Element
mapRectangles f input =
    List.map2
        (\src targetRect -> { src | targetRect = targetRect })
        input
        (input |> List.map .targetRect |> f)


transformPrimitive : Mat4 -> Primitive -> Primitive
transformPrimitive f input =
    case input of
        Images img ->
            Images <| VertexList.transformPosition f img

        Text txt ->
            Text <| VertexList.transformPosition f txt


transformElements : List Element -> List Element
transformElements elements =
    elements
        |> List.map
            (\e ->
                let
                    toOrigin =
                        Mat4.makeTranslate3 -e.sourceRect.xpos -e.sourceRect.ypos 0.0

                    scale =
                        Mat4.makeScale3 (e.targetRect.width / e.sourceRect.width) (e.targetRect.height / e.sourceRect.height) 1.0

                    toTarget =
                        Mat4.makeTranslate3 e.targetRect.xpos e.targetRect.ypos e.zindex

                    transform =
                        Mat4.mul (Mat4.mul toTarget scale) toOrigin
                in
                { e | primitive = e.primitive |> transformPrimitive transform }
            )


toHtml : List Element -> List (Html Msg)
toHtml elements =
    let
        screenWidth =
            1600

        screenHeight =
            900

        buildElementHtml element =
            div
                [ style "position" "absolute"
                , style "width" (String.fromFloat (screenHeight * element.targetRect.width) ++ "px")
                , style "height" (String.fromFloat (screenHeight * element.targetRect.height) ++ "px")
                , style "left" (String.fromFloat (screenHeight * element.targetRect.xpos) ++ "px")
                , style "bottom" (String.fromFloat (screenHeight * element.targetRect.ypos) ++ "px")
                ]
                element.html
    in
    elements
        |> List.map buildElementHtml


toPart : List Element -> Part
toPart elements =
    let
        transformedElements =
            transformElements elements

        accumulateVertices element ( images, text ) =
            case element.primitive of
                Images img ->
                    ( images ++ img, text )

                Text txt ->
                    ( images, text ++ txt )

        accumulated =
            List.foldl accumulateVertices ( [], [] ) transformedElements
    in
    { images = Tuple.first accumulated
    , text = Tuple.second accumulated
    }


entityParameters : List WebGL.Settings.Setting
entityParameters =
    [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
    , DepthTest.default
    ]


toEntities : Textures -> List Part -> List WebGL.Entity
toEntities textures parts =
    let
        perspective =
            Mat4.makeOrtho2D 0.0 (16 / 9) 0.0 1.0

        drawImages =
            WebGL.entityWith
                entityParameters
                Image.vertexShader
                Image.fragmentShader
                (WebGL.triangles <| List.concat <| List.map (\p -> p.images) parts)
                { perspective = perspective, texture = textures.atlas }

        drawText =
            WebGL.entityWith
                entityParameters
                Text.vertexShader
                Text.fragmentShader
                (WebGL.triangles <| List.concat <| List.map (\p -> p.text) parts)
                { perspective = perspective, texture = textures.text }
    in
    [ drawImages
    , drawText
    ]
