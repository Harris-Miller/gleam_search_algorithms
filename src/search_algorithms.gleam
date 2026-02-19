import gleam/function
import gleam/list
import gleam/result
import internal/generalized_search
import internal/search_container.{type EstimateStatePair}

/// Breadth First Search
pub fn breadth_first(
  get_next_states get_next_states: fn(state) -> List(state),
  is_found is_found: fn(state) -> Bool,
  initial_state initial_state: state,
) -> Result(List(state), Nil) {
  generalized_search.generalized_search(
    search_container: search_container.new_queue(),
    make_key: function.identity,
    is_better: fn(_, _) { False },
    get_next_states: fn(estimate_state_pair: EstimateStatePair(state)) {
      get_next_states(estimate_state_pair.1)
      |> list.map(fn(state) { #(0, state) })
    },
    is_found: fn(state: EstimateStatePair(state)) { is_found(state.1) },
    initial_estimate_state_pair: #(0, initial_state),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.1 }) })
}

/// Depth First Search
pub fn depth_first(
  get_next_states get_next_states: fn(state) -> List(state),
  is_found is_found: fn(state) -> Bool,
  initial_state initial_state: state,
) -> Result(List(state), Nil) {
  generalized_search.generalized_search(
    search_container: search_container.new_stack(),
    make_key: function.identity,
    is_better: fn(_, _) { True },
    get_next_states: fn(state: EstimateStatePair(state)) {
      get_next_states(state.1) |> list.map(fn(state) { #(0, state) })
    },
    is_found: fn(state: EstimateStatePair(state)) { is_found(state.1) },
    initial_estimate_state_pair: #(0, initial_state),
  )
  |> result.map(fn(list) { list.map(list, fn(t) { t.1 }) })
}

fn dijkstra_generalized(
  get_next_estimate_state_pairs: fn(EstimateStatePair(state)) ->
    List(EstimateStatePair(state)),
  is_found: fn(state) -> Bool,
  initial_state: state,
) -> Result(#(Int, List(state)), Nil) {
  let unpack = fn(estimate_state_pairs: List(EstimateStatePair(state))) -> #(
    Int,
    List(state),
  ) {
    case estimate_state_pairs {
      [] -> #(0, [])
      _ -> {
        let assert Ok(last) = list.last(estimate_state_pairs)
        let fst = last.0
        let snd = list.map(estimate_state_pairs, fn(t) { t.1 })
        #(fst, snd)
      }
    }
  }

  let result =
    generalized_search.generalized_search(
      search_container: search_container.new_lifo_heap(),
      make_key: fn(t: EstimateStatePair(state)) { t.1 },
      is_better: fn(left, right) { left.0 < right.0 },
      get_next_states: get_next_estimate_state_pairs,
      is_found: fn(t: EstimateStatePair(state)) { is_found(t.1) },
      initial_estimate_state_pair: #(0, initial_state),
    )

  result.map(result, unpack)
}

/// Dijkstra w/ associated transition costs
pub fn dijkstra_assoc(
  get_next_states get_next_states: fn(state) -> List(#(state, Int)),
  is_found is_found: fn(state) -> Bool,
  initial_state initial_state: state,
) {
  let get_next_estimate_state_pairs = fn(
    estimate_state_pair: EstimateStatePair(state),
  ) -> List(EstimateStatePair(state)) {
    let #(current_cost, current_state) = estimate_state_pair
    let next_states = get_next_states(current_state)
    next_states
    |> list.map(fn(state_cost_tuple: #(state, Int)) -> EstimateStatePair(state) {
      #(current_cost + state_cost_tuple.1, state_cost_tuple.0)
    })
  }

  dijkstra_generalized(get_next_estimate_state_pairs, is_found, initial_state)
}

/// Dijkstra
pub fn dijkstra(
  get_next_states get_next_states: fn(state) -> List(state),
  get_next_cost get_next_cost: fn(state, state) -> Int,
  is_found is_found: fn(state) -> Bool,
  initial_state initial_state: state,
) {
  let get_next_estimate_state_pairs = fn(
    estimate_state_pair: EstimateStatePair(state),
  ) -> List(EstimateStatePair(state)) {
    let #(current_cost, current_state) = estimate_state_pair
    let next_states = get_next_states(current_state)
    let next_costs =
      list.map(next_states, fn(next_state) {
        get_next_cost(current_state, next_state) + current_cost
      })
    list.zip(next_costs, next_states)
  }

  dijkstra_generalized(get_next_estimate_state_pairs, is_found, initial_state)
}

fn a_star_generalized(
  get_next_estimate_state_pairs: fn(EstimateStatePair(#(state, Int))) ->
    List(EstimateStatePair(#(state, Int))),
  approx_remaining_cost: fn(state) -> Int,
  is_found: fn(state) -> Bool,
  initial_state: state,
) -> Result(#(Int, List(state)), Nil) {
  let unpack = fn(estimate_state_pairs: List(EstimateStatePair(#(state, Int)))) -> #(
    Int,
    List(state),
  ) {
    case estimate_state_pairs {
      [] -> #(0, [])
      _ -> {
        let assert Ok(last) = list.last(estimate_state_pairs)
        let fst = last.1.1
        let snd = list.map(estimate_state_pairs, fn(states) { states.1.0 })
        #(fst, snd)
      }
    }
  }

  let result =
    generalized_search.generalized_search(
      search_container: search_container.new_lifo_heap(),
      make_key: fn(estimate_state_pair: EstimateStatePair(#(state, Int))) {
        estimate_state_pair.1.0
      },
      is_better: fn(left, right) { left.0 < right.0 },
      get_next_states: get_next_estimate_state_pairs,
      is_found: fn(estimate_state_pair: EstimateStatePair(#(state, Int))) {
        is_found(estimate_state_pair.1.0)
      },
      initial_estimate_state_pair: #(approx_remaining_cost(initial_state), #(
        initial_state,
        0,
      )),
    )

  result.map(result, unpack)
}

/// A* w/ associated transition costs
pub fn a_star_assoc(
  get_next_states get_next_states: fn(state) -> List(#(state, Int)),
  approx_remaining_cost approx_remaining_cost: fn(state) -> Int,
  is_found is_found: fn(state) -> Bool,
  initial_state initial_state: state,
) {
  let get_next_estimate_state_pairs = fn(
    estimate_state_pair: EstimateStatePair(#(state, Int)),
  ) -> List(EstimateStatePair(#(state, Int))) {
    let #(_, #(current_state, current_cost)) = estimate_state_pair
    get_next_states(current_state)
    |> list.map(fn(state_cost_tuple) {
      let remaining = approx_remaining_cost(state_cost_tuple.0)
      let next_cost = current_cost + state_cost_tuple.1
      let next_estimate = next_cost + remaining
      #(next_estimate, #(state_cost_tuple.0, next_cost))
    })
  }

  a_star_generalized(
    get_next_estimate_state_pairs,
    approx_remaining_cost,
    is_found,
    initial_state,
  )
}

/// A*
pub fn a_star(
  get_next_states get_next_states: fn(state) -> List(state),
  get_next_cost get_next_cost: fn(state, state) -> Int,
  approx_remaining_cost approx_remaining_cost: fn(state) -> Int,
  is_found is_found: fn(state) -> Bool,
  initial_state initial_state: state,
) -> Result(#(Int, List(state)), Nil) {
  let get_next_estimate_state_pairs = fn(
    estimate_state_pair: EstimateStatePair(#(state, Int)),
  ) -> List(EstimateStatePair(#(state, Int))) {
    let #(_, #(current_state, current_cost)) = estimate_state_pair
    let next_states = get_next_states(current_state)
    list.map(next_states, fn(next_state) {
      let remaining = approx_remaining_cost(next_state)
      let next_cost = current_cost + get_next_cost(current_state, next_state)
      let next_estimate = next_cost + remaining
      #(next_estimate, #(next_state, next_cost))
    })
  }

  a_star_generalized(
    get_next_estimate_state_pairs,
    approx_remaining_cost,
    is_found,
    initial_state,
  )
}
