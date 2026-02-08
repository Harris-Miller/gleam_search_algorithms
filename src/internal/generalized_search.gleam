import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import internal/container.{type Container}

pub type SearchState(key, value) {
  SearchState(
    current: #(Int, value),
    container: Container(value),
    visited: Set(key),
    paths: Dict(key, List(#(Int, value))),
  )
}

pub fn find_iterate(
  get_next_states: fn(value) -> Result(value, Nil),
  has_found_end: fn(value) -> Bool,
  value: value,
) -> Result(value, Nil) {
  case has_found_end(value) {
    True -> Ok(value)
    False ->
      get_next_states(value)
      |> result.try(find_iterate(get_next_states, has_found_end, _))
  }
}

fn next_search_state(
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
          Ok(old_path) ->
            case is_better(old_path, [state, ..steps_so_far]) {
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
  |> result.map(fn(state) {
    let #(state, container) = state
    SearchState(
      state,
      container,
      set.insert(current.visited, make_key(state)),
      new_paths,
    )
  })
  |> result.try(fn(state) {
    case set.contains(current.visited, make_key(state.current)) {
      True -> next_search_state(is_better, make_key, get_next_states, state)
      False -> Ok(state)
    }
  })
}

pub fn generalized_search(
  container: Container(value),
  make_key: fn(#(Int, value)) -> key,
  is_better: fn(List(#(Int, value)), List(#(Int, value))) -> Bool,
  get_next_states: fn(#(Int, value)) -> List(#(Int, value)),
  has_found_end: fn(#(Int, value)) -> Bool,
  initial_state: #(Int, value),
) -> Result(List(#(Int, value)), Nil) {
  let initial_key = make_key(initial_state)
  let initial_state =
    SearchState(
      initial_state,
      container,
      set.from_list([initial_key]),
      dict.from_list([#(initial_key, [])]),
    )

  let end_result =
    find_iterate(
      next_search_state(is_better, make_key, get_next_states, _),
      fn(state: SearchState(key, value)) { has_found_end(state.current) },
      initial_state,
    )

  let get_steps = fn(state: SearchState(key, value)) {
    let assert Ok(steps) = dict.get(state.paths, make_key(state.current))
    steps
  }

  result.map(end_result, fn(st) { st |> get_steps() |> list.reverse() })
}
