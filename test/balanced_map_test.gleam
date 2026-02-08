import balanced_map
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn insert_test() {
  // insert should add keys if they don't exist
  let balanced_map =
    balanced_map.new()
    |> balanced_map.insert(3, "x")
    |> balanced_map.insert(2, "y")
    |> balanced_map.insert(1, "z")

  let as_list = balanced_map.to_list(balanced_map)
  as_list |> should.equal([#(1, "z"), #(2, "y"), #(3, "x")])

  // or update when they do
  let balanced_map =
    balanced_map
    |> balanced_map.insert(3, "c")
    |> balanced_map.insert(2, "b")
    |> balanced_map.insert(1, "a")

  let as_list = balanced_map.to_list(balanced_map)
  as_list |> should.equal([#(1, "a"), #(2, "b"), #(3, "c")])
}
