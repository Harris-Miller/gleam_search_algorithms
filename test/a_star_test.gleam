import a_star
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import simplifile
import test_utils

pub fn main() {
  gleeunit.main()
}

fn create_height_map() {
  "abcdefghijklmnopqrstuvwxyz"
  |> string.split("")
  |> list.index_map(fn(v, i) { #(v, i + 1) })
  |> dict.from_list()
  |> dict.insert("E", 26)
  |> dict.insert("S", 1)
}

fn heuristic(p1: #(Int, Int)) {
  fn(p2: #(Int, Int)) {
    int.absolute_value(p1.0 - p2.0) + int.absolute_value(p1.1 - p2.1)
  }
}

fn can_move_to(grid: Dict(#(Int, Int), Int)) {
  fn(p1: #(Int, Int), p2: #(Int, Int)) {
    let assert Ok(h1) = dict.get(grid, p1)
    let assert Ok(h2) = dict.get(grid, p2)
    h2 - h1 < 2
  }
}

fn get_next_points(grid: Dict(#(Int, Int), Int)) {
  fn(p: #(Int, Int)) {
    test_utils.get_neighbors(p)
    |> list.filter(dict.has_key(grid, _))
    |> list.filter(can_move_to(grid)(p, _))
  }
}

pub fn a_star_test_hill_climb_finds_expected_solution() {
  // my puzzle input from https://adventofcode.com/2022/day/12
  let assert Ok(content) = simplifile.read("./test/flat_files/hills.txt")

  let grid = test_utils.make_grid(content)
  let height_map = create_height_map()
  let point_heights =
    dict.map_values(grid, fn(_, val) {
      let assert Ok(height) = dict.get(height_map, val)
      height
    })

  let assert Ok(#(start, _)) =
    grid |> dict.to_list() |> list.find(fn(tuple) { tuple.1 == "S" })
  let assert Ok(#(end, _)) =
    grid |> dict.to_list() |> list.find(fn(tuple) { tuple.1 == "E" })

  let assert Ok(#(total_cost, path)) =
    a_star.a_star(
      get_next_points(point_heights),
      fn(_, _) { 1 },
      heuristic(end),
      fn(p) { end == p },
      start,
    )

  // my part one solution for https://adventofcode.com/2022/day/12
  // got this solution originally using https://hackage-content.haskell.org/package/search-algorithms to solve this same problem
  // so if it is the same here, that should be enough to validate that my implementation is correct
  total_cost |> should.equal(412)
  // the cost for all moves is `1`, so path length will be total_cost + 1
  // this should be enough to assume it found the same actual path as my Haskell solution without having to check the individual values
  path |> list.length() |> should.equal(413)
}
