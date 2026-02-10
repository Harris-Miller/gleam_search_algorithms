//// BalancedTree is a Gleam friendly wrapper around erlang's gb_trees module
//// https://www.erlang.org/doc/apps/stdlib/gb_trees.html
//// This only wraps the functionality needed for LIFOHeap, so keeping internal for now.
//// Eventually I'll complete the wrap and move it to its own `balanced_tree` package

import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/set
import gleam/yielder.{type Yielder}

pub type BalancedTree(k, v)

pub type Iter(k, v)

type Order {
  Ordered
  Reversed
}

// Section
// non-public, @external's to gb_trees

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

@external(erlang, "gb_trees", "from_orddict")
pub fn gb_trees_from_orddict(list: List(#(k, v))) -> BalancedTree(k, v)

@external(erlang, "gb_trees", "is_defined")
fn gb_trees_is_defined(key: k, gb_tree: BalancedTree(k, v)) -> Bool

@external(erlang, "gb_trees", "iterator")
fn gb_trees_iterator(tree: BalancedTree(k, v), order: Order) -> Iter(k, v)

@external(erlang, "gb_trees", "map")
fn gb_trees_map(
  fun: fn(k, v) -> a,
  tree: BalancedTree(k, v),
) -> BalancedTree(k, a)

@external(erlang, "gb_trees", "smallest")
fn gb_trees_smallest(from tree: BalancedTree(k, v)) -> #(k, v)

@external(erlang, "gb_trees", "take_smallest")
fn gb_trees_take_smallest(
  from tree: BalancedTree(k, v),
) -> #(k, v, BalancedTree(k, v))

@external(erlang, "gb_trees", "largest")
fn gb_trees_largest(from tree: BalancedTree(k, v)) -> #(k, v)

@external(erlang, "gb_trees_shim", "next_shim")
fn next_shim(iter: Iter(k, v)) -> Result(#(k, v, Iter(kv, v)), Nil)

@external(erlang, "gb_trees", "take_largest")
fn gb_trees_take_largest(
  from tree: BalancedTree(k, v),
) -> #(k, v, BalancedTree(k, v))

// Section
// Public Functions
// Gleam friendly, includes @external's if function signature is already Gleam friendly

/// Notice that this is rarely necessary, but can be motivated when many nodes have been deleted from the tree without further insertions. Rebalancing can then be forced to minimize lookup times, as deletion does not rebalance the tree.
@external(erlang, "gb_trees", "balance")
pub fn balance(tree: BalancedTree(k, v)) -> BalancedTree(k, v)

pub fn combine(
  tree: BalancedTree(k, v),
  other: BalancedTree(k, v),
  with fun: fn(v, v) -> v,
) -> BalancedTree(k, v) {
  // TODO: check efficiency of doing it this way
  other
  |> to_list()
  |> list.fold(tree, fn(acc, kvp) {
    upsert(acc, kvp.0, fn(opt_value) {
      case opt_value {
        option.None -> kvp.1
        option.Some(v) -> fun(v, kvp.1)
      }
    })
  })
}

pub fn delete(
  from tree: BalancedTree(k, v),
  delete key: k,
) -> BalancedTree(k, v) {
  gb_trees_delete_any(key, tree)
}

pub fn drop(
  from tree: BalancedTree(k, v),
  drop disallowed_keys: List(k),
) -> BalancedTree(k, v) {
  let as_set = set.from_list(disallowed_keys)
  filter(tree, fn(k, _) { set.contains(as_set, k) })
}

pub fn each(tree: BalancedTree(k, v), fun: fn(k, v) -> a) -> Nil {
  to_list(tree) |> list.each(fn(kvp) { fun(kvp.0, kvp.1) })
}

pub fn filter(
  in tree: BalancedTree(k, v),
  keeping predicate: fn(k, v) -> Bool,
) -> BalancedTree(k, v) {
  to_list(tree)
  |> list.filter(fn(kvp) { predicate(kvp.0, kvp.1) })
  |> from_list()
  |> balance()
}

/// fold in-order from min-to-max
pub fn fold(
  over tree: BalancedTree(k, v),
  from initial: acc,
  with fun: fn(acc, k, v) -> acc,
) -> acc {
  to_list(tree) |> list.fold(initial, fn(acc, kvp) { fun(acc, kvp.0, kvp.1) })
}

/// fold in-order from max-to-min
pub fn fold_right(
  over tree: BalancedTree(k, v),
  from initial: acc,
  with fun: fn(acc, k, v) -> acc,
) -> acc {
  to_list(tree)
  |> list.reverse()
  |> list.fold(initial, fn(acc, kvp) { fun(acc, kvp.0, kvp.1) })
}

pub fn from_dict(dict: Dict(k, v)) -> BalancedTree(k, v) {
  dict |> dict.to_list() |> gb_trees_from_orddict()
}

pub fn from_list(list: List(#(k, v))) -> BalancedTree(k, v) {
  // gb_trees_from_orddict panics if there are duplicate keys
  // so to both remove duplicates, and mirror dict.from_list()'s behavior of "last one in the list", do dict.from_list() first
  list |> dict.from_list() |> from_dict()
}

@external(erlang, "gb_trees_shim", "lookup_shim")
pub fn get(from gb_tree: BalancedTree(k, v), get key: k) -> Result(v, Nil)

/// Gets the 2-element tuple `#(key, value)` of the next larger key in the Tree.
/// 
/// The tree may not have a larger key, so the tuple is wrapped in a `Result`.
@external(erlang, "gb_trees_shim", "larger_shim")
pub fn get_larger(tree: BalancedTree(k, v), key: k) -> Result(#(k, v), Nil)

pub fn get_max(from tree: BalancedTree(k, v)) -> Result(#(k, v), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_largest() |> Ok()
  }
}

pub fn get_min(from tree: BalancedTree(k, v)) -> Result(#(k, v), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_smallest() |> Ok()
  }
}

/// Gets the 2-element tuple `#(key, value)` of the next smaller key in the Tree.
/// 
/// The tree may not have a smaller key, so the tuple is wrapped in a `Result`.
@external(erlang, "gb_trees_shim", "smaller_shim")
pub fn get_smaller(tree: BalancedTree(k, v), key: k) -> Result(#(k, v), Nil)

pub fn has_key(tree: BalancedTree(k, v), key: k) -> Bool {
  gb_trees_is_defined(key, tree)
}

pub fn insert(
  into tree: BalancedTree(k, v),
  for key: k,
  insert value: v,
) -> BalancedTree(k, v) {
  gb_trees_enter(key, value, tree)
}

@external(erlang, "gb_trees", "is_empty")
pub fn is_empty(tree: BalancedTree(k, v)) -> Bool

fn iterate_internal(tree: BalancedTree(k, v), order: Order) -> Yielder(#(k, v)) {
  let iter = gb_trees_iterator(tree, order)
  yielder.unfold(iter, fn(acc) {
    case next_shim(acc) {
      Error(Nil) -> yielder.Done
      Ok(#(key, value, next_acc)) -> yielder.Next(#(key, value), next_acc)
    }
  })
}

pub fn iterate(tree: BalancedTree(k, v)) -> Yielder(#(k, v)) {
  iterate_internal(tree, Ordered)
}

pub fn iterate_right(tree: BalancedTree(k, v)) -> Yielder(#(k, v)) {
  iterate_internal(tree, Reversed)
}

@external(erlang, "gb_trees", "keys")
pub fn keys(tree: BalancedTree(k, v)) -> List(k)

pub fn map_values(
  in tree: BalancedTree(k, v),
  with fun: fn(k, v) -> a,
) -> BalancedTree(k, a) {
  gb_trees_map(fun, tree)
}

pub fn merge(
  into tree: BalancedTree(k, v),
  from new_entries: BalancedTree(k, v),
) -> BalancedTree(k, v) {
  // TODO: check efficiency of doing it this way
  let tree_as_dict = to_dict(tree)
  let new_entries_as_dict = to_dict(new_entries)
  let merged = dict.merge(tree_as_dict, new_entries_as_dict)
  from_dict(merged)
}

@external(erlang, "gb_trees", "empty")
pub fn new() -> BalancedTree(k, v)

pub fn pop_max(
  from tree: BalancedTree(k, v),
) -> Result(#(#(k, v), BalancedTree(k, v)), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False ->
      tree |> gb_trees_take_largest() |> fn(t) { #(#(t.0, t.1), t.2) } |> Ok()
  }
}

pub fn pop_min(
  from tree: BalancedTree(k, v),
) -> Result(#(#(k, v), BalancedTree(k, v)), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False ->
      tree |> gb_trees_take_smallest() |> fn(t) { #(#(t.0, t.1), t.2) } |> Ok()
  }
}

@external(erlang, "gb_trees", "size")
pub fn size(tree: BalancedTree(k, v)) -> Int

@external(erlang, "gb_trees", "to_list")
pub fn to_list(tree: BalancedTree(k, v)) -> List(#(k, v))

pub fn to_dict(tree: BalancedTree(k, v)) -> Dict(k, v) {
  tree |> to_list() |> dict.from_list()
}

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

@external(erlang, "gb_trees", "values")
pub fn values(tree: BalancedTree(k, v)) -> List(v)
