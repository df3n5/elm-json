module JsonCodec.Decoder where
import Dict
import Json
import JsonCodec.Process (..)

type JsonProcessor = Json.Value -> Output Json.Value

reducejson : [JsonProcessor] -> Output Json.Value -> Output Json.Value
reducejson xs mv = foldl (\f b -> from f b) mv xs 

-- Accessors

delve : [String] -> Json.Value -> Output Json.Value
delve xs mv = reducejson (map getProp xs) (Success mv)

getProp : String -> Json.Value -> Output Json.Value
getProp n json = case json of
                  Json.Object d -> case (Dict.getOrElse Json.Null n d) of
                                     Json.Null -> Error <| decodeError n
                                     v -> Success v
                  _ -> Error <| decodeError n
  
-- Types

type Decoder a = Json.Value -> Output a
data NamedDec a = NDec String (Decoder a)

(:=) : String -> Decoder a -> NamedDec a
(:=) k d = NDec k d

infixr 0 :=

-- Built-in decoders for convenience

string : Decoder String
string v = case v of
                Json.String s -> Success s
                _ -> Error <| decodeError "{string}"

float : Decoder Float
float v = case v of
                  Json.Number n -> Success n
                  _ -> Error <| decodeError "{float}"

int : Decoder Int
int = float `interpretedWith` floor

bool : Decoder Bool
bool v = case v of
                  Json.Boolean b -> Success b
                  _ -> Error <| decodeError "{bool}"

listOf : Decoder a -> Decoder [a]
listOf f v = case v of
                   Json.Array xs -> Success <| successes (map f xs)
                   _ -> Error <| decodeError "{list}"

-- Generic decoders

decodeError n = "Could not decode: '" ++ n ++ "'"

decode : NamedDec a -> (a -> b) -> Decoder b
decode (NDec x fa) g json = getProp x json >>= fa >>= (\a -> Success (g a))

decode2 : NamedDec a -> NamedDec b -> (a -> b -> c) -> Decoder c
decode2 (NDec x fa) (NDec y fb) g json =
  getProp x json >>= fa >>= (\a -> getProp y json >>= fb >>= (\b -> Success (g a b)))

decode3 : NamedDec a -> NamedDec b -> NamedDec c -> (a -> b -> c -> d) -> Decoder d
decode3 (NDec x fa) (NDec y fb) (NDec z fc) g json =
  getProp x json >>= fa >>= (\a -> getProp y json >>= fb >>= 
                                   (\b -> getProp z json >>= fc >>= (\c -> Success (g a b c))))

