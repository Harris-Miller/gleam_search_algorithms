import balanced_tree
import gleam/yielder
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn get_works_with_lookup_shim_test() {
  let tree = balanced_tree.new() |> balanced_tree.insert(5, "a")
  let val = balanced_tree.get(tree, 5)

  val |> should.equal(Ok("a"))
}

pub fn get_smaller_test() {
  let tree = balanced_tree.new() |> balanced_tree.insert(5, "a")

  balanced_tree.get_smaller(tree, 6) |> should.equal(Ok(#(5, "a")))
  balanced_tree.get_smaller(tree, 4) |> should.equal(Error(Nil))
}

pub fn get_larger_test() {
  let tree = balanced_tree.new() |> balanced_tree.insert(5, "a")

  balanced_tree.get_larger(tree, 4) |> should.equal(Ok(#(5, "a")))
  balanced_tree.get_larger(tree, 6) |> should.equal(Error(Nil))
}

pub fn iterate_test() {
  let tree =
    balanced_tree.new()
    |> balanced_tree.insert(5, "a")
    |> balanced_tree.insert(7, "b")
    |> balanced_tree.insert(3, "c")
    |> balanced_tree.insert(1, "d")
    |> balanced_tree.insert(9, "e")

  let output =
    tree
    |> balanced_tree.iterate()
    |> yielder.map(fn(tuple) { tuple.0 })
    |> yielder.to_list()

  output |> should.equal([1, 3, 5, 7, 9])
}

pub fn iterate_right_test() {
  let tree =
    balanced_tree.new()
    |> balanced_tree.insert(5, "a")
    |> balanced_tree.insert(7, "b")
    |> balanced_tree.insert(3, "c")
    |> balanced_tree.insert(1, "d")
    |> balanced_tree.insert(9, "e")

  let output =
    tree
    |> balanced_tree.iterate_right()
    |> yielder.map(fn(tuple) { tuple.0 })
    |> yielder.to_list()

  output |> should.equal([9, 7, 5, 3, 1])
}
