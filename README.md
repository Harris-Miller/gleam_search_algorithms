# search_algorithms

[![Package Version](https://img.shields.io/hexpm/v/search_algorithms)](https://hex.pm/packages/search_algorithms)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/search_algorithms/)

A port of the Haskell [Algorithm.Search](https://hackage-content.haskell.org/package/search-algorithms) module for Gleam

Erlang only - depends on [gb_trees](https://www.erlang.org/doc/apps/stdlib/gb_trees.html). May look into using [External Gleam Fallbacks](https://tour.gleam.run/everything/#advanced-features-external-gleam-fallbacks) for Javascript. Or just port all of gb_trees directly to Gleam. It's not that complicated of a library.

### In Beta

Expect Function, arguments, and return types to be in-flux until 1.0.0 release

```sh
gleam add search_algorithms
```
```gleam
import search_algorithms

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/search_algorithms>.

## Functions

### Searches

* `breadth_first_search`
* `depth_first_search`
* `dijkstra`
* `dijkstra_assoc`
* `a_star`
* `a_star_assoc`

### Helpers (TODO)
* `incremental_costs`
* `pruning`
* `pruning_assoc`

#### Considering
* Some common Heuristic functions such as cartesian and euclidean


## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
