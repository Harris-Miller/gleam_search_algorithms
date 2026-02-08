import generalized_search
import gleam/deque
import gleam/function
import gleam/list
import gleam/result
import internal/search_container.{Queue}

pub fn bfs(
  next: fn(a) -> List(a),
  found: fn(a) -> Bool,
  initial: a,
) -> Result(List(a), Nil) {
  generalized_search.generalized_search(
    Queue(deque.new()),
    function.identity,
    fn(_, _) { False },
    fn(state: #(a, Int)) { next(state.0) |> list.map(fn(a) { #(a, 0) }) },
    fn(state: #(a, Int)) { found(state.0) },
    #(initial, 0),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.0 }) })
}
