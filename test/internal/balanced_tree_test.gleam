import gleeunit
import gleeunit/should
import search_algorithms/internal/balanced_tree

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
