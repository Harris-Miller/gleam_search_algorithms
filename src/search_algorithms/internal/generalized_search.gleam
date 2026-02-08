import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import search_algorithms/internal/container.{type Container}

/// The `Int` in `#(Int, state)` is the min-based priority
/// `breadth_first_search` and `depth_first_search` don't use it, and always set that value to zero
pub type SearchState(state_key, state) {
  SearchState(
    current: #(Int, state),
    // Container takes state -> #(Int, state) internally
    container: Container(state),
    visited: Set(state_key),
    paths: Dict(state_key, List(#(Int, state))),
  )
}

/// recursively search through next states until end us found, or there are no more states to check
pub fn search_until_found(
  get_next_states: fn(value) -> Result(value, Nil),
  has_found_end: fn(value) -> Bool,
  value: value,
) -> Result(value, Nil) {
  case has_found_end(value) {
    True -> Ok(value)
    False ->
      get_next_states(value)
      |> result.try(search_until_found(get_next_states, has_found_end, _))
  }
}

fn get_next_search_state(
  is_better: fn(List(#(Int, value)), List(#(Int, value))) -> Bool,
  make_key: fn(#(Int, value)) -> key,
  get_next_states: fn(#(Int, value)) -> List(#(Int, value)),
  current: SearchState(key, value),
) -> Result(SearchState(key, value), Nil) {
  let update_queue_paths = fn(
    queue_and_paths: #(Container(value), Dict(key, List(#(Int, value)))),
    state: #(Int, value),
  ) {
    let #(queue, paths) = queue_and_paths
    let key = make_key(state)

    case set.contains(current.visited, key) {
      True -> #(queue, paths)
      False -> {
        let assert Ok(steps_so_far) =
          dict.get(current.paths, make_key(current.current))
        let updated_queue = container.push(queue, state)
        let updated_paths = dict.insert(paths, key, [state, ..steps_so_far])

        case dict.get(paths, key) {
          Ok(path) ->
            case is_better(path, [state, ..steps_so_far]) {
              True -> #(updated_queue, updated_paths)
              False -> #(queue, paths)
            }
          Error(Nil) -> #(updated_queue, updated_paths)
        }
      }
    }
  }

  let new_queue_paths = fn() {
    let next_states = get_next_states(current.current)
    list.fold(
      next_states,
      #(current.container, current.paths),
      update_queue_paths,
    )
  }

  let #(new_queue, new_paths) = new_queue_paths()

  new_queue
  |> container.pop()
  |> result.map(fn(state_and_container) {
    let #(state, container) = state_and_container
    SearchState(
      state,
      container,
      set.insert(current.visited, make_key(state)),
      new_paths,
    )
  })
  |> result.try(fn(search_state) {
    case set.contains(current.visited, make_key(search_state.current)) {
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

pub fn generalized_search(
  container: Container(state),
  make_key: fn(#(Int, state)) -> state_key,
  is_better: fn(List(#(Int, state)), List(#(Int, state))) -> Bool,
  get_next_states: fn(#(Int, state)) -> List(#(Int, state)),
  has_found_end: fn(#(Int, state)) -> Bool,
  initial_state: #(Int, state),
) -> Result(List(#(Int, state)), Nil) {
  let initial_key = make_key(initial_state)
  let initial_state =
    SearchState(
      initial_state,
      container,
      set.from_list([initial_key]),
      dict.from_list([#(initial_key, [])]),
    )

  let end_result =
    search_until_found(
      get_next_search_state(is_better, make_key, get_next_states, _),
      fn(search_state: SearchState(state_key, state)) {
        has_found_end(search_state.current)
      },
      initial_state,
    )

  let get_steps = fn(search_state: SearchState(state_key, state)) {
    let assert Ok(steps) =
      dict.get(search_state.paths, make_key(search_state.current))
    steps
  }

  result.map(end_result, fn(st) { st |> get_steps() |> list.reverse() })
}
