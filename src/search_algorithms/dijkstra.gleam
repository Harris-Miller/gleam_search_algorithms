import gleam/list
import gleam/result
import search_algorithms/internal/balanced_tree
import search_algorithms/internal/container
import search_algorithms/internal/generalized_search
import search_algorithms/internal/utils

fn dijkstra_generalized(
  get_next_states_packed: fn(#(Int, value)) -> List(#(Int, value)),
  has_found_end: fn(value) -> Bool,
  initial: value,
) -> Result(#(Int, List(value)), Nil) {
  let unpack = fn(packed_states: List(#(Int, value))) -> #(Int, List(value)) {
    case packed_states {
      [] -> #(0, [])
      packed_states -> {
        let assert Ok(last) = list.last(packed_states)
        let fst = last.0
        let snd = list.map(packed_states, fn(t) { t.1 })
        #(fst, snd)
      }
    }
  }

  let result =
    generalized_search.generalized_search(
      container.LIFOHeap(balanced_tree.new()),
      fn(t: #(Int, value)) { t.1 },
      utils.least_costly,
      get_next_states_packed,
      fn(t: #(Int, value)) { has_found_end(t.1) },
      #(0, initial),
    )

  result.map(result, unpack)
}

pub fn dijkstra_assoc(
  get_next_states: fn(value) -> List(#(value, Int)),
  has_found_end: fn(value) -> Bool,
  initial: value,
) {
  let get_next_states_packed = fn(arg: #(Int, value)) -> List(#(Int, value)) {
    let #(current_cost, current_value) = arg
    let next_states = get_next_states(current_value)
    next_states
    |> list.map(fn(value_cost_tuple: #(value, Int)) -> #(Int, value) {
      #(current_cost + value_cost_tuple.1, value_cost_tuple.0)
    })
  }

  dijkstra_generalized(get_next_states_packed, has_found_end, initial)
}

pub fn dijkstra(
  get_next_states: fn(value) -> List(value),
  get_next_cost: fn(value, value) -> Int,
  has_found_end: fn(value) -> Bool,
  initial: value,
) {
  let get_next_states_packed = fn(arg: #(Int, value)) -> List(#(Int, value)) {
    let #(current_cost, current_value) = arg
    let next_states = get_next_states(current_value)
    let next_costs =
      list.map(next_states, fn(next_value) {
        get_next_cost(current_value, next_value) + current_cost
      })
    list.zip(next_costs, next_states)
  }

  dijkstra_generalized(get_next_states_packed, has_found_end, initial)
}
