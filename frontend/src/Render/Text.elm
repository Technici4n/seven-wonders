module Render.Text exposing (Vertex, fragmentShader, loadTexture, render, vertexShader)

import Data.Font exposing (CharInfo, CommonInfo, Font)
import Dict as Dict
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2, vec2)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import Rectangle exposing (Rectangle)
import Render.VertexList as VertexList exposing (VertexList)
import Task exposing (Task)
import WebGL exposing (Mesh, Shader)
import WebGL.Texture as Texture exposing (Texture, defaultOptions)


loadTexture : Task Texture.Error Texture
loadTexture =
    Texture.loadWith { defaultOptions | minify = Texture.nearest } "/font.png"


render : Font -> Vec3 -> String -> ( VertexList Vertex, Rectangle )
render font color text =
    let
        initialState =
            ( [], 0 )

        appendLetter charInfo ( triangles, totalAdvance ) =
            ( List.concat
                [ triangles
                , renderLetter font color charInfo totalAdvance
                ]
            , totalAdvance + charInfo.xadvance
            )

        finish ( triangles, totalAdvance ) =
            ( triangles
            , { width = toFloat totalAdvance / toFloat font.common.lineHeight
              , height = 1.0
              , xpos = 0.0
              , ypos = 0.0
              }
            )
    in
    text
        |> String.toList
        |> List.filterMap (\char -> Dict.get (String.fromChar char) font.chars)
        |> List.foldl appendLetter initialState
        |> finish


renderLetter : Font -> Vec3 -> CharInfo -> Int -> VertexList Vertex
renderLetter font color charInfo totalAdvance =
    let
        imageHeight =
            toFloat font.common.scaleH

        imageWidth =
            toFloat font.common.scaleW

        x =
            toFloat charInfo.x

        y =
            toFloat charInfo.y

        width =
            toFloat charInfo.width

        height =
            toFloat charInfo.height

        uv_tl =
            vec2 (x / imageWidth) (y / imageHeight)

        uv_tr =
            vec2 ((x + width) / imageWidth) (y / imageHeight)

        uv_br =
            vec2 ((x + width) / imageWidth) ((y + height) / imageHeight)

        uv_bl =
            vec2 (x / imageWidth) ((y + height) / imageHeight)

        lineHeight =
            toFloat font.common.lineHeight

        xy_tl =
            vec2 0.0 (height / lineHeight)

        xy_tr =
            vec2 (width / lineHeight) (height / lineHeight)

        xy_br =
            vec2 (width / lineHeight) 0.0

        xy_bl =
            vec2 0.0 0.0

        offset =
            vec3
                ((toFloat <| totalAdvance + charInfo.xoffset) / lineHeight)
                ((toFloat <| charInfo.yoffset) / lineHeight)
                0.0

        toVec3 v2 =
            let
                xy =
                    Vec2.toRecord v2
            in
            vec3 xy.x xy.y 0.0

        v uv xy =
            { color = color
            , position = Vec3.add (toVec3 xy) offset
            , texturePos = uv
            }

        a =
            v uv_tl xy_tl

        b =
            v uv_tr xy_tr

        c =
            v uv_br xy_br

        d =
            v uv_bl xy_bl
    in
    VertexList.fromFace a b c d


type alias Vertex =
    { color : Vec3
    , position : Vec3
    , texturePos : Vec2
    }


type alias Uniforms =
    { perspective : Mat4
    , texture : Texture
    }


type alias Varying =
    { vcolor : Vec3
    , vtexturePos : Vec2
    }


vertexShader : Shader Vertex Uniforms Varying
vertexShader =
    [glsl|
    attribute vec3 color;
    attribute vec3 position;
    attribute vec2 texturePos;
    uniform mat4 perspective;
    varying vec3 vcolor;
    varying vec2 vtexturePos;

    void main() {
      gl_Position = perspective * vec4(position, 1.0);
      vcolor = color;
      vtexturePos = texturePos;
    }
  |]


fragmentShader : Shader {} Uniforms Varying
fragmentShader =
    [glsl|
    uniform sampler2D texture;
    precision lowp float;
    varying vec3 vcolor;
    precision mediump float;
    varying vec2 vtexturePos;
    float buffer = 0.5;
    float gamma = 0.2;

    void main() {
      float dist = texture2D(texture, vtexturePos).a;
      float alpha = smoothstep(buffer - gamma, buffer + gamma, dist);
      gl_FragColor = vec4(vcolor.rgb, alpha);
    }
  |]
