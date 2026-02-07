pub type GbTree(k, v)

@external(erlang, "gb_trees", "insert")
fn gb_trees_insert(key: k, value: v, gb_tree: GbTree(k, v)) -> GbTree(k, v)

@external(erlang, "gb_trees", "delete_any")
fn gb_trees_delete(key: k, gb_tree: GbTree(k, v)) -> GbTree(k, v)

@external(erlang, "gb_trees", "empty")
pub fn new() -> GbTree(k, v)

pub fn insert(
  into tree: GbTree(k, v),
  for key: k,
  insert value: v,
) -> GbTree(k, v) {
  gb_trees_insert(key, value, tree)
}

pub fn delete(from tree: GbTree(k, v), delete key: k) -> GbTree(k, v) {
  gb_trees_delete(key, tree)
}

@external(erlang, "gb_trees", "take_smallest")
pub fn take_smallest(from tree: GbTree(k, v)) -> #(k, v, GbTree(k, v))
