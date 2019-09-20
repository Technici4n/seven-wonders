module Main exposing (main)

import Browser
import E_Init exposing (init)
import F_Update exposing (update)
import G_View exposing (view)
import H_Subscriptions exposing (subscriptions)



-- MAIN


main =
    Browser.element
        { init = init
        , update = \a b -> update a b |> Debug.log "model"
        , subscriptions = subscriptions
        , view = view
        }
