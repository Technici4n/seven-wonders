module FontInfo exposing (loadFontInfo, CharInfo, CommonInfo, LoadedFontInfo)

import Dict as Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (field, int, list, string, Decoder)

loadFontInfo : (Result Http.Error LoadedFontInfo -> msg) -> Cmd msg
loadFontInfo readyMessage =
  Http.get
    { url = "./font.json"
    , expect = Http.expectJson (Result.map buildLoadedFontInfo >> readyMessage) fontInfoDecoder
    }

getFontInfo : LoadedFontInfo -> String -> Maybe CharInfo
getFontInfo loadedFontInfo string =
  Dict.get string loadedFontInfo.dict

buildLoadedFontInfo : FontInfo -> LoadedFontInfo
buildLoadedFontInfo fontInfo =
  { dict =
    fontInfo.chars
    |> List.map (\charInfo -> (charInfo.char, charInfo))
    |> Dict.fromList
  , commonInfo = fontInfo.common 
  }

type alias LoadedFontInfo =
  { dict : Dict String CharInfo
  , commonInfo : CommonInfo
  }

type alias FontInfo =
  { chars : List CharInfo
  , common : CommonInfo
  }

type alias CommonInfo =
  { lineHeight : Int
  , scaleW : Int
  , scaleH : Int
  }

type alias CharInfo =
  { char : String
  , x : Int
  , y : Int
  , width : Int
  , height : Int
  , xoffset : Int
  , yoffset : Int
  , xadvance : Int
  }

fontInfoDecoder : Decoder FontInfo
fontInfoDecoder =
  Decode.map2 FontInfo
    (field "chars" (list charInfoDecoder))
    (field "common" commonInfoDecoder)

charInfoDecoder : Decoder CharInfo
charInfoDecoder =
  Decode.map8 CharInfo
    (field "char" string)
    (field "x" int)
    (field "y" int)
    (field "width" int)
    (field "height" int)
    (field "xoffset" int)
    (field "yoffset" int)
    (field "xadvance" int)

commonInfoDecoder : Decoder CommonInfo
commonInfoDecoder =
  Decode.map3 CommonInfo
    (field "lineHeight" int)
    (field "scaleW" int)
    (field "scaleH" int)