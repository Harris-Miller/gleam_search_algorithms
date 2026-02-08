import balanced_map
import gleam/list
import gleam/result
import internal/container
import internal/generalized_search
import internal/utils

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
      container.LIFOHeap(balanced_map.new()),
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
