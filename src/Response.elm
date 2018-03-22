module Response exposing (..)

import Shared exposing (Object)
import Request exposing (Request)
import File exposing (File)
import Task exposing (..)

type Content 
    = JSON Object
    | File File
    | Raw String


type alias RespBody =
    { cookeis : Object
    , content : Content
    , status : Int
    , header : Object
    }


type Response
    = Redirect String
    | Reply RespBody
    | Next Request

type Mode a
    = Async (Task String a)
    | Sync a