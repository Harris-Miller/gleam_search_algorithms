import gleam/function
import gleam/list
import gleam/result
import search_algorithms/internal/container
import search_algorithms/internal/generalized_search

pub fn breadth_first_search(
  next: fn(value) -> List(value),
  found: fn(value) -> Bool,
  initial: value,
) -> Result(List(value), Nil) {
  generalized_search.generalized_search(
    container.new_queue(),
    function.identity,
    fn(_, _) { False },
    fn(state: #(Int, value)) {
      next(state.1) |> list.map(fn(value) { #(0, value) })
    },
    fn(state: #(Int, value)) { found(state.1) },
    #(0, initial),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.1 }) })
}
