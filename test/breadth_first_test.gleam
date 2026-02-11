import gleam/dict
import gleam/list
import gleam/set
import gleeunit
import gleeunit/should
import search_algorithms
import simplifile
import test_utils

pub fn main() {
  gleeunit.main()
}

pub fn breadth_first_test() {
  let assert Ok(content) =
    simplifile.read("./test/flat_files/cheese_search.txt")

  let grid = test_utils.make_grid(content)

  let walls =
    grid
    |> dict.to_list()
    |> list.filter(fn(t) { t.1 == "#" })
    |> list.map(fn(t) { t.0 })
    |> set.from_list()

  let assert Ok(#(start, _)) =
    grid |> dict.to_list() |> list.find(fn(tuple) { tuple.1 == "0" })
  let assert Ok(#(end, _)) =
    grid |> dict.to_list() |> list.find(fn(tuple) { tuple.1 == "7" })

  let get_next_states = fn(p: #(Int, Int)) {
    test_utils.get_neighbors(p)
    |> list.filter(fn(p2) { !set.contains(walls, p2) })
  }

  let has_found_end = fn(p: #(Int, Int)) { p == end }

  let assert Ok(path) =
    search_algorithms.breadth_first(get_next_states, has_found_end, start)

  path |> list.length |> should.equal(246)
}
