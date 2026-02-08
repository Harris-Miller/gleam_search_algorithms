import dijkstra
import gleam/dict
import gleam/list
import gleam/set
import gleeunit
import gleeunit/should
import simplifile
import test_utils

// import test_utils

pub fn main() {
  gleeunit.main()
}

pub fn dijkstra_cheese_search_finds_expected_solution_test() {
  // my puzzle input from https://adventofcode.com/2016/day/24
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

  let assert Ok(#(total_cost, _)) =
    dijkstra.dijkstra(get_next_states, fn(_, _) { 1 }, has_found_end, start)

  // my correct part one solution for this day
  // got this solution originally using https://hackage-content.haskell.org/package/search-algorithms
  // so if it is the same here, that should be enough to validate that my implementation is correct
  total_cost |> should.equal(246)
}
