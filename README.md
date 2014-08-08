# JSON in Elm

Convenient and composable translation between JSON and Elm types, with helpful error messages.

The main use cases of this library are:

* Creating composable and extensible JSON codecs.
* Decoding the bits of JSON that you actually care about.

## Decoding examples

### Creating and composing decoders

```haskell
import Json.Decoder (..)
import Json.Process (fromString, into)

type Person = { name: String, age: Int, profession: String }
type Comment = { msg: String, author: Person }
type BlogPost = { content: String, comments: [Comment] }

-- Design the decoders

person : Decoder Person
person = decode3 ("name" := string) ("age" := int) ("profession" := string) Person

comment : Decoder Comment
comment = decode2 ("msg" := string) ("author" := person) Comment

blogpost : Decoder BlogPost
blogpost = decode2 ("content" := string) ("comments" := listOf comment) BlogPost

-- Example data

testdata1 = "{\"name\":\"Jane\",\"age\":47}"
testdata2 = "{\"content\":\"hello world\",\"comments\":[{\"msg\":\"Hello\",\"author\":{\"name\":\"Jane\",\"age\":37,\"profession\":\"Aerospace Engineering\"}},{\"msg\":\"Hello\",\"author\":{\"name\":\"Tim\",\"age\":37,\"profession\":\"Wizard\"}}]}"
testdata3 = "[true,false]"

print : Decoder a -> String -> Element
print decoder s = fromString s `into` decoder |> asText

main = flow down [ print person  testdata1         -- Error ("Could not decode: \'profession\'")
                 , print blogpost testdata2        -- Success { comments = [{ author = { age = 37, ... } ...}], ... }
                 , print (listOf bool) testdata3 ] -- Success [True,False]
```


### Creating accessors and composing them with decoders

```haskell
import Json.Accessor (delve)
import Json.Decoder (..)
import Json.Process (fromString, into, glue)

type Person = { name: String, age: Int, profession: String }

person : Decoder Person
person = decode3 ("name" := string) ("age" := int) ("profession" := string) Person

accessPerson : Decoder Person
accessPerson = delve [ "x", "y", "z" ] `glue` person

-- Example data

testdata1 = "{\"x\":{\"y\":{\"z\":{\"name\":\"Alice\",\"age\":85,\"profession\":\"Science\"}}}}"
testdata2 = "{\"x\":{\"y\":{\"z\":42}}}"

print : Decoder a -> String -> Element
print decoder s = fromString s `into` decoder |> asText

main = flow down [ print accessPerson testdata1   -- Success { age = 85, name = "Alice", ... }
                 , print accessPerson testdata2 ] -- Error ("Could not access a \'name\' in \'Number 42\'")
```
