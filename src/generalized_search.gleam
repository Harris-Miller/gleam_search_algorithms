import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import internal/search_container.{type SearchContainer}

pub type SearchState(state_key, value) {
  SearchState(
    current: #(value, Int),
    queue: SearchContainer(value),
    visited: Set(state_key),
    paths: Dict(state_key, List(#(value, Int))),
  )
}

pub fn find_iterate(
  next: fn(a) -> Result(a, Nil),
  found: fn(a) -> Bool,
  initial: a,
) -> Result(a, Nil) {
  let is_found = found(initial)
  case is_found {
    True -> Ok(initial)
    False -> next(initial) |> result.try(find_iterate(next, found, _))
  }
}

fn next_search_state(
  better: fn(List(#(value, Int)), List(#(value, Int))) -> Bool,
  make_key: fn(#(value, Int)) -> state_key,
  get_next_states: fn(#(value, Int)) -> List(#(value, Int)),
  old: SearchState(state_key, value),
) -> Result(SearchState(state_key, value), Nil) {
  let update_queue_paths = fn(
    queue_and_paths: #(
      SearchContainer(value),
      Dict(state_key, List(#(value, Int))),
    ),
    state: #(value, Int),
  ) {
    let #(queue, paths) = queue_and_paths
    let key = make_key(state)

    case set.contains(old.visited, key) {
      True -> #(queue, paths)
      False -> {
        let assert Ok(steps_so_far) = dict.get(old.paths, make_key(old.current))
        let updated_queue = search_container.push(queue, state)
        let updated_paths = dict.insert(paths, key, [state, ..steps_so_far])

        case dict.get(paths, key) {
          Ok(old_path) ->
            case better(old_path, [state, ..steps_so_far]) {
              True -> #(updated_queue, updated_paths)
              False -> #(queue, paths)
            }
          Error(Nil) -> #(updated_queue, updated_paths)
        }
      }
    }
  }

  let new_queue_paths = fn() {
    let next_states = get_next_states(old.current)
    list.fold(next_states, #(old.queue, old.paths), update_queue_paths)
  }

  let #(new_queue, new_paths) = new_queue_paths()

  new_queue
  |> search_container.pop()
  |> result.map(fn(state) {
    let #(state, container) = state
    SearchState(
      state,
      container,
      set.insert(old.visited, make_key(state)),
      new_paths,
    )
  })
  |> result.try(fn(state) {
    case set.contains(old.visited, make_key(state.current)) {
      True -> next_search_state(better, make_key, get_next_states, state)
      False -> Ok(state)
    }
  })
}

pub fn generalized_search(
  container: SearchContainer(value),
  make_key: fn(#(value, Int)) -> state_key,
  better: fn(List(#(value, Int)), List(#(value, Int))) -> Bool,
  next: fn(#(value, Int)) -> List(#(value, Int)),
  found: fn(#(value, Int)) -> Bool,
  initial: #(value, Int),
) -> Result(List(#(value, Int)), Nil) {
  let initial_key = make_key(initial)
  let initial_state =
    SearchState(
      initial,
      container,
      set.from_list([initial_key]),
      dict.from_list([#(initial_key, [])]),
    )

  let end_result =
    find_iterate(
      next_search_state(better, make_key, next, _),
      fn(state: SearchState(state_key, value)) { found(state.current) },
      initial_state,
    )

  let get_steps = fn(state: SearchState(state_key, value)) {
    let assert Ok(steps) = dict.get(state.paths, make_key(state.current))
    steps
  }

  result.map(end_result, fn(st) { st |> get_steps() |> list.reverse() })
}
