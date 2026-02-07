import gleeunit
import gleeunit/should
import internal/gb_tree as gb

pub fn main() {
  gleeunit.main()
}

pub fn insert_test() {
  // insert should add keys if they don't exist
  let gb_tree =
    gb.new() |> gb.insert(3, "x") |> gb.insert(2, "y") |> gb.insert(1, "z")

  let as_list = gb.to_list(gb_tree)
  as_list |> should.equal([#(1, "z"), #(2, "y"), #(3, "x")])

  // or update when they do
  let gb_tree =
    gb_tree |> gb.insert(3, "c") |> gb.insert(2, "b") |> gb.insert(1, "a")

  let as_list = gb.to_list(gb_tree)
  as_list |> should.equal([#(1, "a"), #(2, "b"), #(3, "c")])
}
