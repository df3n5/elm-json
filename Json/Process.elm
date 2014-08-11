module Json.Process where

{-| A Process represents a passing from some input to a special `Output`.

# Creation
@docs process

# Composition
@docs (>>>), mappedTo, or, and, split

# Trasformation
@docs from, into, (>>=), collapsel

-}

import Json
import Json.Output (..)

type Process a b = a -> Output b

{-| Create a `Process` from a function.

      isRightAnswer : Process Float Bool
      isRightAnswer = process floor >>> process ((==) 42)
-}
process : (a -> b) -> Process a b
process f a = output <| f a

{-| Get an `Output b` from passing an `Output a` through a `Process a b`.

      isRightAnswer : Output Int -> Output Bool
      isRightAnswer o = process ((==) 42) `from` o
-}
from : Process a b -> Output a -> Output b
from f = cata f Error

{-| Same as `from`, but with the arguments interchanged.

      isRightAnswer : Output Int -> Output Bool
      isRightAnswer o = o `into` process ((==) 42)
-}
into : Output a -> Process a b -> Output b
into = flip from

{-| Alias for `into`.

      isRightAnswer : Output Int -> Output Bool
      isRightAnswer o = o >>= process ((==) 42)
-}
(>>=) : Output a -> Process a b -> Output b
(>>=) = into

{-| Compose two Processes.

      isRightAnswer : Process [a] Bool
      isRightAnswer = process length `glue` process ((==) 42)
-}
glue : Process a b -> Process b c -> Process a c
glue f g = (\a -> f a >>= g)

{-| Alias for `glue`.

      isRightAnswer : Process [a] Bool
      isRightAnswer = process length >>> process ((==) 42)
-}
(>>>) : Process a b -> Process b c -> Process a c
(>>>) = glue

{-| Adds a pure transformation to the output of a Process.

      isRightAnswer : Process Int Bool
      isRightAnswer = map (((==) 42) . floor) (process (\n -> 42.5))
-}
map : (b -> c) -> Process a b -> Process a c
map f p = (\a -> p a >>= (\b -> output (f b)))

{-| Same as `map`, but with the arguments interchanged.

      isRightAnswer : Process Int Bool
      isRightAnswer = (process (\n -> 42.5)) `mappedTo` (((==) 42) . floor) 
-}
mappedTo : Process a b -> (b -> c) -> Process a c
mappedTo = flip map

{-| Collapse a list of endo-Processes, from the left.

      isRightAnswer : Output Bool
      isRightAnswer = let o = collapsel (output 0) [ process (\_ -> 21)
                                                    , process ((+) 21) ]
                      in o `into` process ((==) 42)
-}
collapsel : Output a -> [Process a a] -> Output a
collapsel ob xs = foldl (\p o -> o >>= p) ob xs 

{-| Add two processes as disjunctive alternatives.
If the first Process evaluates to an Error, the second Process will 
be evaluated.
-}
or : Process a b -> Process a b -> Process a b
or p1 p2 = (\a -> let o1 = p1 a
                      p3 = (\a -> cata (\_ -> o1) (\_ -> p2 a) o1)
                  in p3 a)

{-| Given two processes, make one with the respective input/output pairs.
-}
split : Process a b -> Process c d -> Process (a,c) (b,d)
split pab pcd (a,c) =
  let ob = pab a
      od = pcd c
  in ob >>= (\b -> od >>= process (\d -> (b,d)))

{-| Pair the output of two processes on a given input.
-}
and : Process a b -> Process a c -> Process a (b,c)
and pab pac = process (\a -> (a,a)) >>> (pab `split` pac)
