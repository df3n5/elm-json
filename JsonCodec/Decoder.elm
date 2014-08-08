module JsonCodec.Decoder where

{-| Tools for translating JSON to Elm types.

# Type and Constructors
@docs Decoder, fromString, (:=)

-}

import Json
import JsonCodec.Process (..)
import JsonCodec.Output (fromMaybe, Success, Error, successes)
import JsonCodec.Accessor (..)

{-| A Decoder is a Process that takes a Json.Value and produces some 
value `a`.
-}
type Decoder a = Process Json.Value a

{-| A Decoder tagged with a property name, expected to be found in 
a Json.Value.
-}
data NamedDec a = NDec PropertyName (Decoder a)

{-| Constructor of decoders with a name.
-}
(:=) : PropertyName -> Decoder a -> NamedDec a
(:=) k d = NDec k d

infixr 0 :=

{-| Create simple error message.
-}
decoderErrorMsg : String -> String
decoderErrorMsg s = "Could not decode: '" ++ s ++ "'"

-- Built-in decoders --

string : Decoder String
string v = case v of
                Json.String s -> Success s
                _ -> Error <| decoderErrorMsg "{string}"

float : Decoder Float
float v = case v of
                  Json.Number n -> Success n
                  _ -> Error <| decoderErrorMsg "{float}"

int : Decoder Int
int = float `interpretedWith` floor

bool : Decoder Bool
bool v = case v of
                  Json.Boolean b -> Success b
                  _ -> Error <| decoderErrorMsg "{bool}"

listOf : Decoder a -> Decoder [a]
listOf f v = case v of
                   Json.Array xs -> Success <| successes (map f xs)
                   _ -> Error <| decoderErrorMsg "{list}"

{-| A Process from String to Json.Value for convenience.

      isRightAnswer : String -> Output Bool
      isRightAnswer s = fromString s >>= int >>= (\n -> Success <| n == 42)
-}
fromString : Process String Json.Value
fromString = (\s -> fromMaybe (Json.fromString s))

-- Generic decoder --

decode1 : NamedDec a1 -> (a1 -> b) -> Decoder b
decode1 (NDec x1 fa1) g json = 
  getVal x1 json 
  >>= fa1 >>= 
  (\a1 -> Success (g a1))

decode2 : NamedDec a1 -> NamedDec a2 -> (a1 -> a2 -> b) -> Decoder b
decode2 (NDec x1 fa1) (NDec x2 fa2) g json =
  getVal x1 json 
  >>= fa1 >>= 
  (\a1 -> getVal x2 json 
          >>= fa2 >>= 
          (\a2 -> Success (g a1 a2)))

decode3 : NamedDec a1 -> NamedDec a2 -> NamedDec a3 -> (a1 -> a2 -> a3 -> b) -> Decoder b
decode3 (NDec x1 fa1) (NDec x2 fa2) (NDec x3 fa3) g json =
  getVal x1 json 
  >>= fa1 >>= 
  (\a1 -> getVal x2 json 
          >>= fa2 >>= 
          (\a2 -> getVal x3 json
                  >>= fa3 >>= 
                  (\a3 -> Success (g a1 a2 a3))))

decode = decode1
