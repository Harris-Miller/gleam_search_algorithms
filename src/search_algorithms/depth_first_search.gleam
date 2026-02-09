import gleam/function
import gleam/list
import gleam/result
import search_algorithms/internal/generalized_search
import search_algorithms/internal/search_container

pub fn depth_first_search(
  next: fn(value) -> List(value),
  found: fn(value) -> Bool,
  initial: value,
) -> Result(List(value), Nil) {
  generalized_search.generalized_search(
    search_container.new_stack(),
    function.identity,
    fn(_, _) { True },
    fn(state: #(Int, value)) {
      next(state.1) |> list.map(fn(value) { #(0, value) })
    },
    fn(state: #(Int, value)) { found(state.1) },
    #(0, initial),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.1 }) })
}
