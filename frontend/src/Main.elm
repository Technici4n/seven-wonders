import Browser
import E_Init exposing (init)
import F_Update exposing (update)
import G_View exposing (view)
import H_Subscriptions exposing (subscriptions)

-- MAIN

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }