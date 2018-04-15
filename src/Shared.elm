module Shared exposing (..)

import Dict exposing (Dict)
import File exposing (File, Encoding)
import Task


type Mode error value model
    = Async (Task.Task error value)
    | Sync value
    | State (model -> (Mode error (model, value) model))

type Answer a
    = Redirect String
    | Reply (Response a)
    | Next (Request a)

type alias Object =
    Dict String String


type Msg a model
    = Input (Request a)
    | Output (Response a)
    | Error String
    | SyncState (model -> (model, Answer a model)) (Request a)
    | AsyncState (Task.Task a (model -> (model, Answer a model))) (Request a)


type Content a
    = JSON String
    | Data String (File a)
    | Text String String
    | Empty


type alias Response a =
    { cookeis : Object
    , id: String
    , content : Content a
    , status : Int
    , header : Object
    }


type Protocol
    = HTTP
    | HTTPS


type alias ReqValue a b =
    { url : String
    , id : String
    , time : Int
    , content : Content a
    , cookies : b
    , cargo : Object
    , ip : String
    , host : String
    , protocol : Protocol
    }


type Request a
    = Get (ReqValue a Object)
    | Post (ReqValue a Object)
    | Put (ReqValue a Object)
    | Delete (ReqValue a Object)


response =
    { cookeis = Dict.empty
    , id = ""
    , content = Empty 
    , status = 200
    , header = Dict.empty
    }