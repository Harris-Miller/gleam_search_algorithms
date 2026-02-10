import gleeunit
import gleeunit/should
import internal/balanced_tree

pub fn main() {
  gleeunit.main()
}

pub fn insert_test() {
  // insert should add keys if they don't exist
  let balanced_tree =
    balanced_tree.new()
    |> balanced_tree.insert(3, "x")
    |> balanced_tree.insert(2, "y")
    |> balanced_tree.insert(1, "z")

  let as_list = balanced_tree.to_list(balanced_tree)
  as_list |> should.equal([#(1, "z"), #(2, "y"), #(3, "x")])

  // or update when they do
  let balanced_tree =
    balanced_tree
    |> balanced_tree.insert(3, "c")
    |> balanced_tree.insert(2, "b")
    |> balanced_tree.insert(1, "a")

  let as_list = balanced_tree.to_list(balanced_tree)
  as_list |> should.equal([#(1, "a"), #(2, "b"), #(3, "c")])
}
