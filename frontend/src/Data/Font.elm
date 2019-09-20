module Data.Font exposing (CharInfo, CommonInfo, Font, fontDecoder)

import Dict as Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder, field, index, int, list, string)


fontDecoder : Decoder Font
fontDecoder =
    Decode.map buildLoadedFontInfo fontInfoDecoder


buildLoadedFontInfo : RawFontInfo -> Font
buildLoadedFontInfo fontInfo =
    { chars =
        fontInfo.chars
            |> List.map (\charInfo -> ( charInfo.char, charInfo ))
            |> Dict.fromList
    , common = fontInfo.common
    }


type alias Font =
    { chars : Dict String CharInfo
    , common : CommonInfo
    }


type alias RawFontInfo =
    { chars : List CharInfo
    , common : CommonInfo
    }


type alias CommonInfo =
    { lineHeight : Int
    , scaleW : Int
    , scaleH : Int
    , whitestCell : ( Int, Int )
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


fontInfoDecoder : Decoder RawFontInfo
fontInfoDecoder =
    Decode.map2 RawFontInfo
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
    Decode.map4 CommonInfo
        (field "lineHeight" int)
        (field "scaleW" int)
        (field "scaleH" int)
        (field "whitestCell" <|
            Decode.map2 Tuple.pair
                (index 0 int)
                (index 1 int)
        )
