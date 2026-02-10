//// BalancedTree is a Gleam friendly wrapper around erlang's gb_trees module
//// https://www.erlang.org/doc/apps/stdlib/gb_trees.html
//// This only wraps the functionality needed for LIFOHeap, so keeping internal for now.
//// Eventually I'll complete the wrap and move it to its own `balanced_tree` package

import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/set
import gleam/yielder.{type Yielder}

/// A Balanced Tree of keys and values.
///
/// Any type can be used for the keys and values of a tree, but all the keys
/// must be of the same type and all the values must be of the same type.
///
/// Each key can only be present in a tree once.
///
/// BalancedTrees _are_ ordered, unlike `gleam/dict`, and are a good solution for when your code
/// relies on the ordering of of the entries, such as a Heap or PriorityQueue.
///
/// See [the Erlang map module](https://erlang.org/doc/man/maps.html) for more
/// information.
///
pub type BalancedTree(k, v)

/// gb_trees.iter/2
type Iter(k, v)

/// For `gb_trees.iterate/2`
type Order {
  Ordered
  Reversed
}

// Section: non-public
// @external's to gb_trees

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

// Section: Public Functions
// Gleam friendly, includes @external's if function signature is already Gleam friendly

/// Notice that this is rarely necessary, but can be motivated when many nodes have been deleted from the tree without further insertions. Rebalancing can then be forced to minimize lookup times, as deletion does not rebalance the tree.
@external(erlang, "gb_trees", "balance")
pub fn balance(tree: BalancedTree(k, v)) -> BalancedTree(k, v)

/// Creates a new tree from a pair of given frees by combining their entries.
///
/// If there are entries with the same keys in both trees the given function is used to determine the new value to use in the resulting dict.
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

/// Creates a new tree from a given tree with all the same entries except for the one with a given key, if it exists.
pub fn delete(
  from tree: BalancedTree(k, v),
  delete key: k,
) -> BalancedTree(k, v) {
  gb_trees_delete_any(key, tree)
}

// Creates a new tree from a given tree with all the same entries except any with keys found in a given list.
pub fn drop(
  from tree: BalancedTree(k, v),
  drop disallowed_keys: List(k),
) -> BalancedTree(k, v) {
  let as_set = set.from_list(disallowed_keys)
  filter(tree, fn(k, _) { set.contains(as_set, k) })
}

/// Calls a function for each key and value in a tree, discarding the return value.
///
/// Useful for producing a side effect for every item of a tree.
pub fn each(tree: BalancedTree(k, v), fun: fn(k, v) -> a) -> Nil {
  to_list(tree) |> list.each(fn(kvp) { fun(kvp.0, kvp.1) })
}

// Creates a new tree from a given tree, minus any entries that a given function returns False for.
pub fn filter(
  in tree: BalancedTree(k, v),
  keeping predicate: fn(k, v) -> Bool,
) -> BalancedTree(k, v) {
  to_list(tree)
  |> list.filter(fn(kvp) { predicate(kvp.0, kvp.1) })
  |> from_list()
  |> balance()
}

/// Reduces a list of elements into a single value by calling a given function on each element, in order from min-key to max-key
///
/// This function runs in linear time.
pub fn fold(
  over tree: BalancedTree(k, v),
  from initial: acc,
  with fun: fn(acc, k, v) -> acc,
) -> acc {
  to_list(tree) |> list.fold(initial, fn(acc, kvp) { fun(acc, kvp.0, kvp.1) })
}

/// Reduces a list of elements into a single value by calling a given function on each element, in order from max-key to min-key
///
/// This function runs in linear time.
pub fn fold_right(
  over tree: BalancedTree(k, v),
  from initial: acc,
  with fun: fn(acc, k, v) -> acc,
) -> acc {
  to_list(tree)
  |> list.reverse()
  |> list.fold(initial, fn(acc, kvp) { fun(acc, kvp.0, kvp.1) })
}

/// Converts a `Dict(k, v)` into a `BalancedTree(k, v)`
pub fn from_dict(dict: Dict(k, v)) -> BalancedTree(k, v) {
  dict |> dict.to_list() |> gb_trees_from_orddict()
}

/// Converts a list of 2-element tuples `#(key, value)` to a tree.
///
/// If two tuples have the same key the last one in the list will be the one that is present in the tree.
pub fn from_list(list: List(#(k, v))) -> BalancedTree(k, v) {
  // gb_trees_from_orddict panics if there are duplicate keys
  // so to both remove duplicates, and mirror dict.from_list()'s behavior of "last one in the list", do dict.from_list() first
  list |> dict.from_list() |> from_dict()
}

/// Fetches a value from a tree for a given key.
///
/// The tree may not have a value for the key, so the value is wrapped in a Result.
@external(erlang, "gb_trees_shim", "lookup_shim")
pub fn get(from gb_tree: BalancedTree(k, v), get key: k) -> Result(v, Nil)

/// Gets the 2-element tuple `#(key, value)` of the next larger key in the Tree.
/// 
/// The tree may not have a larger key, so the tuple is wrapped in a `Result`.
@external(erlang, "gb_trees_shim", "larger_shim")
pub fn get_larger(tree: BalancedTree(k, v), key: k) -> Result(#(k, v), Nil)

/// Fetches the key-value pair for the largest key in the tree.
///
/// Returns `Error(Nil)` when the tree is empty, otherwise `Ok(#(k, v))`
pub fn get_max(from tree: BalancedTree(k, v)) -> Result(#(k, v), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_largest() |> Ok()
  }
}

/// Fetches the key-value pair for the smallest key in the tree.
///
/// Returns `Error(Nil)` when the tree is empty, otherwise `Ok(#(k, v))`
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

/// Determines whether or not a value is present in the tree for a given key.
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

/// Determines whether or not the tree is empty.
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

/// Gets a list of all keys in a given dict.
///
/// BalancedTrees are ordered. Keys are returned ordered min-to-max.
@external(erlang, "gb_trees", "keys")
pub fn keys(tree: BalancedTree(k, v)) -> List(k)

/// Updates all values in a given tree by calling a given function on each key and value.
pub fn map_values(
  in tree: BalancedTree(k, v),
  with fun: fn(k, v) -> a,
) -> BalancedTree(k, a) {
  gb_trees_map(fun, tree)
}

/// Creates a new tree from a pair of given trees by combining their entries.
///
/// If there are entries with the same keys in both trees the entry from the second tree takes precedence.
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

/// Creates a fresh tree that contains no values.
@external(erlang, "gb_trees", "empty")
pub fn new() -> BalancedTree(k, v)

/// Gets the max key-value pair in the tree, returning the pair and a new tree without that pair.
pub fn pop_max(
  from tree: BalancedTree(k, v),
) -> Result(#(#(k, v), BalancedTree(k, v)), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False ->
      tree |> gb_trees_take_largest() |> fn(t) { #(#(t.0, t.1), t.2) } |> Ok()
  }
}

/// Gets the min key-value pair in the tree, returning the pair and a new tree without that pair.
pub fn pop_min(
  from tree: BalancedTree(k, v),
) -> Result(#(#(k, v), BalancedTree(k, v)), Nil) {
  case is_empty(tree) {
    True -> Error(Nil)
    False ->
      tree |> gb_trees_take_smallest() |> fn(t) { #(#(t.0, t.1), t.2) } |> Ok()
  }
}

/// Determines the number of key-value pairs in the dict.
/// 
/// Unlike gleam/dict, this function must iterate over the tree and runs in linear time time
@external(erlang, "gb_trees", "size")
pub fn size(tree: BalancedTree(k, v)) -> Int

/// Converts the dict to a list of 2-element tuples #(key, value), one for each key-value pair in the dict.
///
/// The tuples in the list are ordered by Key
@external(erlang, "gb_trees", "to_list")
pub fn to_list(tree: BalancedTree(k, v)) -> List(#(k, v))

pub fn to_dict(tree: BalancedTree(k, v)) -> Dict(k, v) {
  tree |> to_list() |> dict.from_list()
}

/// Creates a new tree with one entry inserted or updated using a given function.
///
/// If there was not an entry in the tree for the given key then the function gets None as its argument, otherwise it gets Some(value).
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

/// Gets a list of all values in a given tree.
/// 
/// BalancedTrees are ordered. Values are guaranteed to be in min-to-max order based on their associated Keys.
@external(erlang, "gb_trees", "values")
pub fn values(tree: BalancedTree(k, v)) -> List(v)
