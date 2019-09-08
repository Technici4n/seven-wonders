module Main exposing (main)

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Font exposing (Font)
import Html exposing (text, Html)
import Html.Attributes exposing (width, height, style)
import Json.Decode exposing (Value)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.CardPart as Card
import Render.Primitive as Primitive
import Render.Text as Text exposing (Vertex)
import Task
import WebGL exposing (Mesh, Shader)
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest
import WebGL.Texture exposing (Texture)

main : Program Value Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , subscriptions = \_ -> onAnimationFrameDelta TimeElapsed
    , update = update
    }

type alias Text =
  { fontInfo : Font
  , mesh : Mesh Vertex
  }

type alias Model =
  { text : Maybe Text
  , texture : Maybe Texture
  , time : Float
  }

type Msg
  = TextureLoaded (Result WebGL.Texture.Error Texture)
  | TimeElapsed Float
  | FontInfoLoaded (Maybe Font)

init : Value -> ( Model, Cmd Msg )
init _ =
  ( { text = Nothing
    , texture = Nothing
    , time = 0.0
    }
  , Cmd.batch
    [ Text.loadTexture
      |> Task.attempt TextureLoaded
    , Font.load (Result.toMaybe >> FontInfoLoaded)
    ] 
  )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    TextureLoaded textureLoadResult ->
      case textureLoadResult of
        Ok texture ->
          ( { model | texture = Just texture }, Cmd.none )
        Err e ->
          ( model, Cmd.none )
    TimeElapsed delta -> ( { model | time = model.time + delta}, Cmd.none )
    FontInfoLoaded maybeFontInfo ->
      case maybeFontInfo of
        Just fontInfo ->
          let
            text =
              { fontInfo = fontInfo
              , mesh = WebGL.triangles <| List.concat
                  [ Card.getBackground fontInfo (vec3 0.5 0.5 0.5)
                  , Card.getResourceStripe fontInfo (vec3 0.4 0.2 0.0)
                  , Card.getImage fontInfo (vec3 0.4 0.4 0.0)
                  , Card.getText fontInfo (String.toUpper "NORMALÀÉÈÊ")
                  , Card.getResourceCost
                    [ Primitive.octogon fontInfo (vec3 0.0 0.0 0.0)
                    ]
                  ]
              }
          in ( { model | text = Just text }, Cmd.none )
        Nothing ->
          ( model, Cmd.none )


view : Model -> Html Msg
view model =
  case Maybe.map2 Tuple.pair model.texture model.text of
    Nothing -> text "Texture not loaded yet"
    Just (texture, text) ->
      WebGL.toHtmlWith
        [ WebGL.alpha True
        , WebGL.depth 1
        , WebGL.clearColor 0.95 0.87 0.89 1.0
        , WebGL.antialias
        ]
        [ width 800
        , height 800
        , style "display" "block"
        ]
        [ WebGL.entityWith
            [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
            , DepthTest.default
            ]
            Text.vertexShader
            Text.fragmentShader
            text.mesh
            { perspective = perspective 0.0, texture = texture }
        ]

perspective : Float -> Mat4
perspective t =
  let
    currentPos = vec3 (2 * sin (t/1000)) 0.0 (2 * cos (t/1000))
    posOffset = vec3 0.35 0.5 0
    pos = Vec3.add currentPos posOffset
  in
    Mat4.mul
      (Mat4.makePerspective 45 1 0.01 100)
      (Mat4.makeLookAt pos (vec3 0.35 0.5 0) (vec3 0 1 0))

type alias Uniforms =
  { offset : Float
  , perspective : Mat4
  }