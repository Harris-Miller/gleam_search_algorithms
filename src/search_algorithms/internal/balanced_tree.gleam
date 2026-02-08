//// BalancedTree is a Gleam friendly wrapper around erlang's gb_trees module
//// https://www.erlang.org/doc/apps/stdlib/gb_trees.html
//// This only wraps the functionality needed for LIFOHeap, so keeping internal for now.
//// Eventually I'll complete the wrap and move it to its own `balanced_tree` package

import gleam/option

pub type BalancedTree(k, v)

/// ErlangOption
/// Same as `Option`, but instead of `Some`, it's `Value`
/// 
/// the sole purpose of this type is to translate the return of gb_tress.lookup/2 to a Gleam type 
/// that return type is `none | {value, a}`, where `none` and `value` are Atoms
/// this works because Gleam way-ways translates Generic Type constructors to atoms, or tuples of atom + variables
/// eg:
/// * None -> `none`
/// * Value(a) -> `(value, a)`
type ErlangOption(a) {
  Value(a)
  None
}

// Section
// external gb_trees
// non-public

@external(erlang, "gb_trees", "delete_any")
fn gb_trees_delete_any(
  key: k,
  gb_tree: BalancedTree(k, v),
) -> BalancedTree(k, v)

@external(erlang, "gb_trees", "enter")
fn gb_trees_enter(
  key: k,
  value: v,
  gb_tree: BalancedTree(k, v),
) -> BalancedTree(k, v)

@external(erlang, "gb_trees", "lookup")
fn gb_trees_lookup(key: k, gb_tree: BalancedTree(k, v)) -> ErlangOption(v)

@external(erlang, "gb_trees", "empty")
pub fn new() -> BalancedTree(k, v)

@external(erlang, "gb_trees", "is_empty")
fn gb_trees_is_empty(tree: BalancedTree(k, v)) -> Bool

@external(erlang, "gb_trees", "smallest")
fn gb_trees_smallest(from tree: BalancedTree(k, v)) -> #(k, v)

@external(erlang, "gb_trees", "take_smallest")
fn gb_trees_take_smallest(
  from tree: BalancedTree(k, v),
) -> #(k, v, BalancedTree(k, v))

@external(erlang, "gb_trees", "largest")
fn gb_trees_largest(from tree: BalancedTree(k, v)) -> #(k, v)

@external(erlang, "gb_trees", "take_largest")
fn gb_trees_take_largest(
  from tree: BalancedTree(k, v),
) -> #(k, v, BalancedTree(k, v))

// Section
// Public Functions

pub fn delete(
  from tree: BalancedTree(k, v),
  delete key: k,
) -> BalancedTree(k, v) {
  gb_trees_delete_any(key, tree)
}

pub fn insert(
  into tree: BalancedTree(k, v),
  for key: k,
  insert value: v,
) -> BalancedTree(k, v) {
  gb_trees_enter(key, value, tree)
}

pub fn get(from gb_tree: BalancedTree(k, v), get key: k) -> Result(v, Nil) {
  case gb_trees_lookup(key, gb_tree) {
    Value(v) -> Ok(v)
    None -> Error(Nil)
  }
}

pub fn get_max(from tree: BalancedTree(k, v)) -> Result(#(k, v), Nil) {
  case gb_trees_is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_largest() |> Ok()
  }
}

pub fn get_min(from tree: BalancedTree(k, v)) -> Result(#(k, v), Nil) {
  case gb_trees_is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_smallest() |> Ok()
  }
}

pub fn take_max(
  from tree: BalancedTree(k, v),
) -> Result(#(k, v, BalancedTree(k, v)), Nil) {
  case gb_trees_is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_take_largest() |> Ok()
  }
}

pub fn take_min(
  from tree: BalancedTree(k, v),
) -> Result(#(k, v, BalancedTree(k, v)), Nil) {
  case gb_trees_is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_take_smallest() |> Ok()
  }
}

@external(erlang, "gb_trees", "to_list")
pub fn to_list(tree: BalancedTree(k, v)) -> List(#(k, v))

pub fn upsert(
  in tree: BalancedTree(k, v),
  update key: k,
  with fun: fn(option.Option(v)) -> v,
) -> BalancedTree(k, v) {
  get(tree, key)
  |> option.from_result()
  |> fun()
  |> gb_trees_enter(key, _, tree)
}
