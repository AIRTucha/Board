module Parser exposing(..)

import List exposing (reverse)
import String exposing(toFloat, toInt, dropLeft, left, length, uncons, cons, fromChar, startsWith)
import Dict exposing(..)
import Maybe
import Result
import Tuple 

type SubURL 
    = ParsePath String
    | ParseFloat
    | ParseInt
    | ParseStr
    | ParseAny
    | ParseQuery


type URL
    = OrderedURL Char URL URL
    | UnorderedURL Char (List URL)
    | NodeURL SubURL


type URLValue
    = Interger Int
    | Floating Float
    | Str String
    | MultyValue (List URLValue)
    | Failure String
    | Query (Dict String String)
    | Succes


p : String -> URL
p string =
    NodeURL <| ParsePath string


float : URL
float =
    NodeURL ParseFloat


int : URL
int =
    NodeURL ParseInt


str: URL 
str = 
    NodeURL ParseStr


any: URL
any = 
    NodeURL ParseAny


query : URL
query =
    NodeURL ParseQuery


-- parser : URL -> String -> URLValue
-- parser value string =
--     parsingLoop value [] string


-- parsingLoop : URL -> (List URLValue) -> String -> URLValue
-- parsingLoop url result string =
--     case url of
--         OrderedURL char sub nextURL ->
--             case sub of
--                 ParsePath path ->
--                     string 
--                         |> break char 
--                         |> Result.andThen (checkEqual path)
--                         |> ignorValue result
--                         |> parseNext nextURL


--                 ParseFloat ->
--                     string
--                         |> break char 
--                         |> Result.andThen (parseValue String.toFloat)
--                         |> packValue Floating result
--                         |> parseNext nextURL
                           

--                 ParseInt ->
--                     string  
--                         |> break char
--                         |> Result.andThen (parseValue String.toInt)
--                         |> packValue Interger result
--                         |> parseNext nextURL


--                 ParseQuery ->
--                     string
--                         |> break char
--                         |> Result.andThen (parseValue parseQuery)
--                         |> packValue Query result
--                         |> parseNext nextURL

                    
--                 ParseStr ->
--                     string
--                         |> break char
--                         |> packValue Str result
--                         |> parseNext nextURL
                    

--                 ParseAny ->
--                     string
--                         |> break char
--                         |> Result.map Tuple.second
--                         |> ignorValue result
--                         |> parseNext nextURL


--         NodeURL node ->
--             case node of
--                 ParsePath path ->
--                     checkEqual path ( string, "" )
--                         |> ignorValue result
--                         |> packResult
                

--                 ParseFloat ->
--                     parseValue String.toFloat ( string, "" )
--                         |> packValue Floating result
--                         |> packResult
                

--                 ParseInt ->
--                     parseValue String.toInt ( string, "" )
--                         |> packValue Interger result
--                         |> packResult

                                
--                 ParseStr ->
--                     parseValue Ok ( string, "" )
--                         |> packValue Str result
--                         |> packResult


--                 ParseAny ->
--                     makeValue result 


--                 ParseQuery ->
--                     parseValue parseQuery ( string, "" )
--                         |> packValue Query result
--                         |> packResult


--         UnorderedURL _ _ _ ->
--             Failure "unimplemented"
    
        
parseValue parse (head, tail) =
    parse head
        |> Result.map ( \ value -> ( value, tail ))


parseQuery : String -> Result String (Dict String String)
parseQuery string =
    let 
        (oks, errs) =
            string
                |> String.split "&"
                |> List.map (break '=')
                |> partitionLift ( [], [] )
    in
        if (List.length errs) > 0 then
            errs
                |> String.concat
                |> String.append "Query is not correct: "
                |> Err
        else
            oks
                |> Dict.fromList
                |> Ok


partitionLift (succes, failure) list =
    case list of
        [] ->
            ( succes, failure )


        (Ok head) :: tail ->
            partitionLift ( head :: succes, failure ) tail
        

        (Err head) :: tail ->
            partitionLift ( succes, head :: failure ) tail


packValue packer result input =
    case input of
        Ok ( value, tail ) ->
            ( packer value :: result, tail)
                |> Ok
        
        Err error ->
            result 
                |> (::) ( Failure error )
                |> Err


checkEqual path (string, tail) =
    if path == string then
        Ok tail
    else 
        Err ( path ++ " is not " ++ string)


ignorValue result input =
    case input of
        Ok tail ->
            (result, tail)
                |> Ok
        
        Err error ->
            result 
                |> (::) ( Failure error )
                |> Err


-- parseNext url result =
--     case result of
--         Ok ( value, tail ) ->
--             parsingLoop url value tail
        
--         Err url ->
--             makeValue url
            

packResult result =
    case result of 
        Ok (value, _) ->
            value
                |> makeValue 
            
        Err error ->
            error 
                |> makeValue 


makeValue: (List URLValue) -> URLValue
makeValue list =
    case list of
        head :: [] ->
            head 

        head :: tail ->
            MultyValue <| reverse list 
        
        [] ->
            Succes

-- (</>): URL -> URL -> URL
(</>) = orderedDevider '/'


-- (<?>): URL -> URL -> URL
(<?>) = orderedDevider '?'


-- (<&>): URL -> URL -> URL
(<&>) = unorderedDevider '&'

(<%>) = unorderedDevider '%'


orderedDevider char url1 url2 =
    OrderedURL char url1 url2


unorderedDevider char url1 url2 =
    case url1 of
        OrderedURL _ a _ ->
            merge ( Tuple.first >> (::) ) char url1 a url2


        UnorderedURL char1 urls1 ->
            if char1 == char then 
                merge ( Tuple.second >> List.append ) char url1 urls1 url2
            else 
                merge ( Tuple.first >> (::) ) char url1 urls1 url2
        

        NodeURL a ->
            merge ( Tuple.first >> (::) ) char url1 a url2


merge joinUrls char url1 urls1 url2 =
    case url2 of
        UnorderedURL char2 urls2 ->
            if char == char2 then
                joinUrls (url1, urls1) urls2 
                    |> UnorderedURL char 
            else
                [url1, url2]
                    |> UnorderedURL char 
        
        _ ->
            [url1, url2] 
                |> UnorderedURL char 
    

-- devider : ( Char -> SubURL -> URL -> URL ) -> Char -> SubURL -> URL -> URL
-- devider packer char url1 url2 =
--     case url2 of
--         OrderedURL char1 sub1 nextURL1 ->
--             OrderedURL char1 sub1 <| devider packer char nextURL1 url2

--         UnorderedURL char1 currURL nextURL ->
--             UnorderedURL char1 currURL <| devider packer char nextURL url2
        
--         URLNode sub1 ->
--             packer char sub1 url2

--         URLEnd ->
--             URLEnd


orderedPacker =
    OrderedURL 


-- unorderedPacker char sub1 url2 =
--     UnorderedURL char [sub1] url2


break: Char -> String -> Result String ( String, String )
break char string =
    case splitOnce char "" string of
        Just ( head, tail ) ->
            Ok ( head, tail )

        Nothing ->
            Err <| string ++ " does not contain " ++ (fromChar char)


splitOnce: Char -> String -> String -> Maybe ( String, String )
splitOnce char head tail =
    case uncons tail of 
        Just (first, rest) ->
            if first == char then 
                Just ( head, rest ) 
            else 
                splitOnce char (head ++ fromChar first) rest
        
        Nothing ->
            Nothing