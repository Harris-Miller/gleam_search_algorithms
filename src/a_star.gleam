import balanced_map
import gleam/list
import gleam/result
import internal/container
import internal/generalized_search

fn least_costly(left: List(#(Int, a)), right: List(#(Int, a))) -> Bool {
  case left, right {
    [#(cost_left, _), ..], [#(cost_right, _), ..] -> cost_right < cost_left
    // logically these will never happen
    [], _ -> False
    _, [] -> False
  }
}

fn unpack(packed_states: List(#(Int, #(value, Int)))) -> #(Int, List(value)) {
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

fn a_star_generalized(
  get_next_states_packed: fn(#(Int, #(value, Int))) ->
    List(#(Int, #(value, Int))),
  approx_remaining_cost: fn(value) -> Int,
  has_found_end: fn(value) -> Bool,
  initial: value,
) -> Result(#(Int, List(value)), Nil) {
  generalized_search.generalized_search(
    container.LIFOHeap(balanced_map.new()),
    fn(packed_state: #(Int, #(value, Int))) { packed_state.1.0 },
    least_costly,
    get_next_states_packed,
    fn(packed_state: #(Int, #(value, Int))) { has_found_end(packed_state.1.0) },
    #(approx_remaining_cost(initial), #(initial, 0)),
  )
  |> result.map(unpack)
}

// -- | @aStarAssocM@ is a monadic version of 'aStarAssoc': it has support for
// -- monadic  @next@, @remaining@, and @found@ parameters.
// aStarAssocM :: (Monad m, Num cost, Ord cost, Ord state)
//   => (state -> m [(state, cost)])
//   -- ^ function to generate list of neighboring states with associated
//   -- transition costs given the current state
//   -> (state -> m cost)
//   -- ^ Estimate on remaining cost given a state
//   -> (state -> m Bool)
//   -- ^ Predicate to determine if solution found. 'aStarM' returns the shortest
//   -- path to the first state for which this predicate returns 'True'.
//   -> state
//   -- ^ Initial state
//   -> m (Maybe (cost, [state]))
//   -- ^ (Total cost, list of steps) for the first path found which satisfies the
//   -- given predicate
// aStarAssocM nextM remainingM foundM initial = do
//   remaining_init <- remainingM initial
//   fmap2 unpack $ generalizedSearchM emptyLIFOHeap snd2 leastCostly nextM'
//     (foundM . snd2) (remaining_init, (0, initial))
//   where
//     nextM' (_, (old_cost, old_st)) = do
//       new_states <- nextM old_st
//       sequence $ update_stateM <$> new_states
//       where
//         update_stateM new_st = do
//           remaining <- remainingM (fst new_st)
//           let new_cost = old_cost + (snd new_st)
//               new_est = new_cost + remaining
//           return (new_est, (new_cost, fst new_st))
//     unpack [] = (0, [])
//     unpack packed_states =
//       (fst . snd . last $ packed_states, map snd2 packed_states)
//     snd2 = snd . snd
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
