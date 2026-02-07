import gleam/dict.{type Dict}

// import gleam/list
// import gleam/result
import gleam/set.{type Set}
import internal/search_container.{type SearchContainer}

pub type SearchState(state_key, state) {
  SearchState(
    current: state,
    queue: SearchContainer(Int, state),
    visited: Set(state_key),
    paths: Dict(state_key, List(state)),
  )
}
