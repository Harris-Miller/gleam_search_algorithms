import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import internal/search_container.{type EstimateStatePair, type SearchContainer}

/// A Record that represents the current State of the search.
/// 
/// Generics:
/// * `state_key` is used for `==` equality for the values and keys in visited and paths respectively
/// * `state` can be anything
/// 
/// Properties:
/// * `current` - the `state` tied to the "cost" it took to get there
/// * `search_container` - The abstract data structure set by the type of search, used to `push` state, and `pop` back in a specific order
///   * Implementations include a `Stack`, `Queue`, and `LIFOHeap`
/// * `visited` - a `Set` of visited locations, key'd by `state_key`
/// * `paths` - a collection of how we got to `state_key` by a list of `EstimateStatePair(state)`
/// 
/// Notes:
/// The `Int` in `EstimateStatePair(state)` is the min-based priority needed for the LIFOHeap container.
/// It is unused by `Stack` and `Queue`, and will always be `0` for them
pub type SearchState(state_key, state) {
  SearchState(
    current: EstimateStatePair(state),
    search_container: SearchContainer(state),
    visited: Set(state_key),
    paths: Dict(state_key, List(EstimateStatePair(state))),
  )
}

/// recursively search through next states until end us found, or there are no more states to check
pub fn search_until_found(
  get_next_states: fn(state) -> Result(state, Nil),
  is_found: fn(state) -> Bool,
  state: state,
) -> Result(state, Nil) {
  case is_found(state) {
    True -> Ok(state)
    False ->
      get_next_states(state)
      |> result.try(search_until_found(get_next_states, is_found, _))
  }
}

fn get_next_search_state(
  is_better: fn(EstimateStatePair(state), EstimateStatePair(state)) -> Bool,
  make_key: fn(EstimateStatePair(state)) -> key,
  get_next_states: fn(EstimateStatePair(state)) ->
    List(EstimateStatePair(state)),
  search_state: SearchState(key, state),
) -> Result(SearchState(key, state), Nil) {
  let update_queue_paths = fn(
    search_container_and_paths: #(
      SearchContainer(state),
      Dict(key, List(EstimateStatePair(state))),
    ),
    estimate_state_pair: EstimateStatePair(state),
  ) {
    let #(search_container, paths) = search_container_and_paths
    let key = make_key(estimate_state_pair)

    case set.contains(search_state.visited, key) {
      True -> #(search_container, paths)
      False -> {
        let assert Ok(steps_so_far) =
          dict.get(search_state.paths, make_key(search_state.current))
        let updated_queue =
          search_container.push(search_container, estimate_state_pair)
        let updated_paths =
          dict.insert(paths, key, [estimate_state_pair, ..steps_so_far])

        case dict.get(paths, key) {
          Error(Nil) -> #(updated_queue, updated_paths)
          Ok(path) -> {
            // logically, paths will always contain at least one item, so this is safe
            let assert [previous_estimate_state_pair, ..] = path
            case is_better(previous_estimate_state_pair, estimate_state_pair) {
              True -> #(updated_queue, updated_paths)
              False -> #(search_container, paths)
            }
          }
        }
      }
    }
  }

  let #(new_search_container, new_paths) = {
    let next_states = get_next_states(search_state.current)
    list.fold(
      next_states,
      #(search_state.search_container, search_state.paths),
      update_queue_paths,
    )
  }

  new_search_container
  |> search_container.pop()
  |> result.map(fn(tuple) {
    let #(estimate_state_pair, search_container) = tuple
    SearchState(
      estimate_state_pair,
      search_container,
      set.insert(search_state.visited, make_key(estimate_state_pair)),
      new_paths,
    )
  })
  |> result.try(fn(search_state) {
    case set.contains(search_state.visited, make_key(search_state.current)) {
      True ->
        get_next_search_state(
          is_better,
          make_key,
          get_next_states,
          search_state,
        )
      False -> Ok(search_state)
    }
  })
}

/// a clever search that, based on the container type and the is_better function,
/// can be used to do A*, Dijkstra, BFS, or DFS
pub fn generalized_search(
  search_container search_container: SearchContainer(state),
  make_key make_key: fn(EstimateStatePair(state)) -> state_key,
  is_better is_better: fn(EstimateStatePair(state), EstimateStatePair(state)) ->
    Bool,
  get_next_states get_next_states: fn(EstimateStatePair(state)) ->
    List(EstimateStatePair(state)),
  is_found is_found: fn(EstimateStatePair(state)) -> Bool,
  initial_estimate_state_pair initial_estimate_state_pair: EstimateStatePair(
    state,
  ),
) -> Result(List(EstimateStatePair(state)), Nil) {
  let initial_key = make_key(initial_estimate_state_pair)
  let search_state =
    SearchState(
      initial_estimate_state_pair,
      search_container,
      set.from_list([initial_key]),
      dict.from_list([#(initial_key, [])]),
    )

  let end_result =
    search_until_found(
      get_next_search_state(is_better, make_key, get_next_states, _),
      fn(search_state: SearchState(state_key, state)) {
        is_found(search_state.current)
      },
      search_state,
    )

  let get_steps = fn(search_state: SearchState(state_key, state)) {
    let assert Ok(steps) =
      dict.get(search_state.paths, make_key(search_state.current))
    steps
  }

  result.map(end_result, fn(st) { st |> get_steps() |> list.reverse() })
}
