module Main exposing (main)

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Font exposing (Font)
import Html exposing (text, Html)
import Html.Attributes exposing (width, height, style)
import Http
import Json.Decode as Decode exposing (Value)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.Card as Card exposing (RenderParameters)
import Render.Image as Image
import Render.Primitive as Primitive
import Render.Text as Text exposing (Vertex)
import Task
import TextureAtlas exposing (TextureAtlas)
import WebGL exposing (Mesh, Shader)
import WebGL.Settings
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

type alias Scene =
  { images : Mesh Image.Vertex
  , text : Mesh Text.Vertex
  }

type alias Textures =
  { atlas : Texture
  , text : Texture
  }

type alias Model =
  { renderParams : Maybe RenderParameters
  , scene : Maybe Scene
  , textures : Maybe Textures
  , time : Float
  }

type Msg
  = RenderParamsLoaded (Maybe RenderParameters)
  | TexturesLoaded (Maybe Textures)
  | TimeElapsed Float

renderParametersDecoder : Decode.Decoder RenderParameters
renderParametersDecoder =
  Decode.map2 RenderParameters
    (Decode.field "textures" TextureAtlas.textureAtlasDecoder)
    (Decode.field "font" Font.fontDecoder)

loadRenderParameters : Cmd Msg
loadRenderParameters =
  Http.get
    { url = "/data.json"
    , expect = Http.expectJson (Result.toMaybe >> RenderParamsLoaded) renderParametersDecoder
    }

loadTextures : Cmd Msg
loadTextures =
  Task.map2 Textures
    Image.loadTexture
    Text.loadTexture
  |> Task.attempt (Result.toMaybe >> TexturesLoaded)

init : Value -> ( Model, Cmd Msg )
init _ =
  ( { renderParams = Nothing
    , scene = Nothing
    , textures = Nothing
    , time = 0.0
    }
  , Cmd.batch
    [ loadRenderParameters
    , loadTextures
    ]
  )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let
    noUpdate = (model, Cmd.none)
  in
    case msg of
      RenderParamsLoaded maybeRenderParams ->
        case maybeRenderParams of
          Just renderParams ->
            ( { model | renderParams = Just renderParams, scene = Just (scene renderParams) }, Cmd.none )
          Nothing -> noUpdate
      TexturesLoaded maybeTextures ->
        case maybeTextures of
          Just textures ->
            ( { model | textures = Just textures }, Cmd.none )
          Nothing -> noUpdate
      TimeElapsed delta -> ( { model | time = model.time + delta}, Cmd.none )

scene : RenderParameters -> Scene
scene params =
  let (text, images) = Card.render params Card.testCard
  in
    { images = WebGL.triangles (Image.render params.atlas "Marché")
    , text = WebGL.triangles []
    }

renderParameters : List WebGL.Settings.Setting
renderParameters =
  [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
  , DepthTest.default
  ]

view : Model -> Html Msg
view model =
  case Maybe.map2 Tuple.pair model.scene model.textures of
    Nothing -> text "Texture not loaded yet"
    Just (sc, textures) ->
      WebGL.toHtmlWith
        [ WebGL.alpha True
        , WebGL.depth 1
        , WebGL.clearColor 0.6 0.6 0.6 1.0
        , WebGL.antialias
        ]
        [ width 1800
        , height 800
        , style "display" "block"
        ]
        [ WebGL.entityWith
            renderParameters
            Text.vertexShader
            Text.fragmentShader
            sc.text
            { perspective = perspective 0.0, texture = textures.text }
        , WebGL.entityWith
            renderParameters
            Image.vertexShader
            Image.fragmentShader
            sc.images
            { perspective = perspective 0.0, texture = textures.atlas }
        ]

perspective : Float -> Mat4
perspective t =
  let
    currentPos = vec3 (2 * sin (t/1000)) 0.0 (2 * cos (t/1000))
    posOffset = vec3 0.35 0.5 5
    pos = Vec3.add currentPos posOffset
  in
    Mat4.mul
      (Mat4.makePerspective 45 (1800/800) 0.01 100)
      (Mat4.makeLookAt pos (vec3 0.35 0.5 0) (vec3 0 1 0))

type alias Uniforms =
  { offset : Float
  , perspective : Mat4
  }