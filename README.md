# search_algorithms

A port of the Haskell's [Algorithm.Search](https://hackage-content.haskell.org/package/search-algorithms) module for Gleam

[![Package Version](https://img.shields.io/hexpm/v/search_algorithms_gleam)](https://hex.pm/packages/search_algorithms_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/search_algorithms_gleam/)

Erlang only - depends on [gb_trees](https://www.erlang.org/doc/apps/stdlib/gb_trees.html). May look into using [External Gleam Fallbacks](https://tour.gleam.run/everything/#advanced-features-external-gleam-fallbacks) for Javascript. Or just port all of gb_trees directly to Gleam. It's not that complicated of a library.

WIP. Expect sudden API changes until 1.0.0

```sh
gleam add search_algorithms_gleam
```
```gleam
import search_algorithms

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/search_algorithms_gleam>.

## Functions

### Searches

* `breadth_first`
* `depth_first`
* `dijkstra`
* `dijkstra_assoc`
* `a_star`
* `a_star_assoc`

#### Considering
* Some common Heuristic functions such as cartesian and euclidean


## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
