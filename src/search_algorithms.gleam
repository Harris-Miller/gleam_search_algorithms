import gleam/function
import gleam/list
import gleam/result
import internal/generalized_search
import internal/search_container
import internal/utils

/// Breadth First Search
pub fn breadth_first(
  next next: fn(state) -> List(state),
  found found: fn(state) -> Bool,
  initial initial: state,
) -> Result(List(state), Nil) {
  generalized_search.generalized_search(
    search_container: search_container.new_queue(),
    make_key: function.identity,
    is_better: fn(_, _) { False },
    get_next_states: fn(state: #(Int, state)) {
      next(state.1) |> list.map(fn(state) { #(0, state) })
    },
    has_found_end: fn(state: #(Int, state)) { found(state.1) },
    initial_state: #(0, initial),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.1 }) })
}

/// Depth First Search
pub fn depth_first(
  next: fn(state) -> List(state),
  found: fn(state) -> Bool,
  initial: state,
) -> Result(List(state), Nil) {
  generalized_search.generalized_search(
    search_container: search_container.new_stack(),
    make_key: function.identity,
    is_better: fn(_, _) { True },
    get_next_states: fn(state: #(Int, state)) {
      next(state.1) |> list.map(fn(state) { #(0, state) })
    },
    has_found_end: fn(state: #(Int, state)) { found(state.1) },
    initial_state: #(0, initial),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.1 }) })
}

fn dijkstra_generalized(
  get_next_states_packed: fn(#(Int, state)) -> List(#(Int, state)),
  has_found_end: fn(state) -> Bool,
  initial: state,
) -> Result(#(Int, List(state)), Nil) {
  let unpack = fn(packed_states: List(#(Int, state))) -> #(Int, List(state)) {
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
      search_container: search_container.new_lifo_heap(),
      make_key: fn(t: #(Int, state)) { t.1 },
      is_better: utils.least_costly,
      get_next_states: get_next_states_packed,
      has_found_end: fn(t: #(Int, state)) { has_found_end(t.1) },
      initial_state: #(0, initial),
    )

  result.map(result, unpack)
}

/// Dijkstra w/ associated transition costs
pub fn dijkstra_assoc(
  get_next_states: fn(state) -> List(#(state, Int)),
  has_found_end: fn(state) -> Bool,
  initial: state,
) {
  let get_next_states_packed = fn(arg: #(Int, state)) -> List(#(Int, state)) {
    let #(current_cost, current_state) = arg
    let next_states = get_next_states(current_state)
    next_states
    |> list.map(fn(state_cost_tuple: #(state, Int)) -> #(Int, state) {
      #(current_cost + state_cost_tuple.1, state_cost_tuple.0)
    })
  }

  dijkstra_generalized(get_next_states_packed, has_found_end, initial)
}

/// Dijkstra
pub fn dijkstra(
  get_next_states: fn(state) -> List(state),
  get_next_cost: fn(state, state) -> Int,
  has_found_end: fn(state) -> Bool,
  initial: state,
) {
  let get_next_states_packed = fn(arg: #(Int, state)) -> List(#(Int, state)) {
    let #(current_cost, current_state) = arg
    let next_states = get_next_states(current_state)
    let next_costs =
      list.map(next_states, fn(next_state) {
        get_next_cost(current_state, next_state) + current_cost
      })
    list.zip(next_costs, next_states)
  }

  dijkstra_generalized(get_next_states_packed, has_found_end, initial)
}

fn a_star_generalized(
  get_next_states_packed: fn(#(Int, #(state, Int))) ->
    List(#(Int, #(state, Int))),
  approx_remaining_cost: fn(state) -> Int,
  has_found_end: fn(state) -> Bool,
  initial: state,
) -> Result(#(Int, List(state)), Nil) {
  let unpack = fn(packed_states: List(#(Int, #(state, Int)))) -> #(
    Int,
    List(state),
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
      search_container: search_container.new_lifo_heap(),
      make_key: fn(packed_state: #(Int, #(state, Int))) { packed_state.1.0 },
      is_better: utils.least_costly,
      get_next_states: get_next_states_packed,
      has_found_end: fn(packed_state: #(Int, #(state, Int))) {
        has_found_end(packed_state.1.0)
      },
      initial_state: #(approx_remaining_cost(initial), #(initial, 0)),
    )

  result.map(result, unpack)
}

/// A* w/ associated transition costs
pub fn a_star_assoc(
  get_next_states: fn(state) -> List(#(state, Int)),
  approx_remaining_cost: fn(state) -> Int,
  has_found_end: fn(state) -> Bool,
  initial: state,
) {
  let get_next_states_packed = fn(arg: #(Int, #(state, Int))) -> List(
    #(Int, #(state, Int)),
  ) {
    let #(_, #(current_state, current_cost)) = arg
    get_next_states(current_state)
    |> list.map(fn(state_cost_tuple) {
      let remaining = approx_remaining_cost(state_cost_tuple.0)
      let next_cost = current_cost + state_cost_tuple.1
      let next_estimate = next_cost + remaining
      #(next_estimate, #(state_cost_tuple.0, next_cost))
    })
  }

  a_star_generalized(
    get_next_states_packed,
    approx_remaining_cost,
    has_found_end,
    initial,
  )
}

/// A*
pub fn a_star(
  get_next_states: fn(state) -> List(state),
  get_next_cost: fn(state, state) -> Int,
  approx_remaining_cost: fn(state) -> Int,
  has_found_end: fn(state) -> Bool,
  initial: state,
) -> Result(#(Int, List(state)), Nil) {
  let get_next_states_packed = fn(arg: #(Int, #(state, Int))) -> List(
    #(Int, #(state, Int)),
  ) {
    let #(_, #(current_state, current_cost)) = arg
    let next_states = get_next_states(current_state)
    list.map(next_states, fn(next_state) {
      let remaining = approx_remaining_cost(next_state)
      let next_cost = current_cost + get_next_cost(current_state, next_state)
      let next_estimate = next_cost + remaining
      #(next_estimate, #(next_state, next_cost))
    })
  }

  a_star_generalized(
    get_next_states_packed,
    approx_remaining_cost,
    has_found_end,
    initial,
  )
}
