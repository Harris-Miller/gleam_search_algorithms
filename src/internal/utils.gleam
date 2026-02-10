import gleam/list

pub fn least_costly(left: List(#(Int, a)), right: List(#(Int, a))) -> Bool {
  case left, right {
    [#(cost_left, _), ..], [#(cost_right, _), ..] -> cost_right < cost_left
    // logically these will never happen
    [], _ -> False
    _, [] -> False
  }
}

/// A utility function that calculates the "incremental" costs between neighboring states
/// TODO: expose this publicly?
pub fn incremental_costs(
  calc_cost: fn(state, state) -> Int,
  states: List(state),
) -> List(Int) {
  list.zip(states, list.drop(states, 1))
  |> list.map(fn(t) { calc_cost(t.0, t.1) })
}
