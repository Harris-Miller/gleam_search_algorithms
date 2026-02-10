import gleam/function
import gleam/list
import gleam/result
import internal/generalized_search
import internal/search_container
import internal/utils

/// Breadth First Search
pub fn breadth_first_search(
  next: fn(value) -> List(value),
  found: fn(value) -> Bool,
  initial: value,
) -> Result(List(value), Nil) {
  generalized_search.generalized_search(
    search_container.new_queue(),
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

/// Depth First Search
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
      search_container.new_lifo_heap(),
      fn(t: #(Int, value)) { t.1 },
      utils.least_costly,
      get_next_states_packed,
      fn(t: #(Int, value)) { has_found_end(t.1) },
      #(0, initial),
    )

  result.map(result, unpack)
}

/// Dijsktra
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

/// Dijsktra
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

/// A*
fn a_star_generalized(
  get_next_states_packed: fn(#(Int, #(value, Int))) ->
    List(#(Int, #(value, Int))),
  approx_remaining_cost: fn(value) -> Int,
  has_found_end: fn(value) -> Bool,
  initial: value,
) -> Result(#(Int, List(value)), Nil) {
  let unpack = fn(packed_states: List(#(Int, #(value, Int)))) -> #(
    Int,
    List(value),
  ) {
    case packed_states {
      [] -> #(0, [])
      packed_states -> {
        let assert Ok(last) = list.last(packed_states)
        let fst = last.1.1
        let snd = list.map(packed_states, fn(states) { states.1.0 })
        #(fst, snd)
      }
    }
  }

  let result =
    generalized_search.generalized_search(
      search_container.new_lifo_heap(),
      fn(packed_state: #(Int, #(value, Int))) { packed_state.1.0 },
      utils.least_costly,
      get_next_states_packed,
      fn(packed_state: #(Int, #(value, Int))) {
        has_found_end(packed_state.1.0)
      },
      #(approx_remaining_cost(initial), #(initial, 0)),
    )

  result.map(result, unpack)
}

/// A*
pub fn a_star_assoc(
  get_next_states: fn(value) -> List(#(value, Int)),
  approx_remaining_cost: fn(value) -> Int,
  has_found_end: fn(value) -> Bool,
  initial: value,
) {
  let get_next_states_packed = fn(arg: #(Int, #(value, Int))) -> List(
    #(Int, #(value, Int)),
  ) {
    let #(_, #(current_value, current_cost)) = arg
    get_next_states(current_value)
    |> list.map(fn(value_cost_tuple) {
      let remaining = approx_remaining_cost(value_cost_tuple.0)
      let next_cost = current_cost + value_cost_tuple.1
      let next_estimate = next_cost + remaining
      #(next_estimate, #(value_cost_tuple.0, next_cost))
    })
  }

  a_star_generalized(
    get_next_states_packed,
    approx_remaining_cost,
    has_found_end,
    initial,
  )
}

pub fn a_star(
  get_next_states: fn(value) -> List(value),
  get_next_cost: fn(value, value) -> Int,
  approx_remaining_cost: fn(value) -> Int,
  has_found_end: fn(value) -> Bool,
  initial: value,
) -> Result(#(Int, List(value)), Nil) {
  let get_next_states_packed = fn(arg: #(Int, #(value, Int))) -> List(
    #(Int, #(value, Int)),
  ) {
    let #(_, #(current_value, current_cost)) = arg
    let next_states = get_next_states(current_value)
    list.map(next_states, fn(next_value) {
      let remaining = approx_remaining_cost(next_value)
      let next_cost = current_cost + get_next_cost(current_value, next_value)
      let next_estimate = next_cost + remaining
      #(next_estimate, #(next_value, next_cost))
    })
  }

  a_star_generalized(
    get_next_states_packed,
    approx_remaining_cost,
    has_found_end,
    initial,
  )
}
