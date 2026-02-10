//// BalancedTree is a Gleam friendly wrapper around erlang's gb_trees module
//// https://www.erlang.org/doc/apps/stdlib/gb_trees.html
//// This only wraps the functionality needed for LIFOHeap, so keeping internal for now.
//// Eventually I'll complete the wrap and move it to its own `balanced_tree` package

import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/set

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

@external(erlang, "gb_trees", "is_defined")
fn gb_trees_is_defined(key: k, gb_tree: BalancedTree(k, v)) -> Bool

@external(erlang, "gb_trees", "lookup")
fn gb_trees_lookup(key: k, gb_tree: BalancedTree(k, v)) -> ErlangOption(v)

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

@external(erlang, "gb_trees", "take_largest")
fn gb_trees_take_largest(
  from tree: BalancedTree(k, v),
) -> #(k, v, BalancedTree(k, v))

// Section
// Public Functions

/// Notice that this is rarely necessary, but can be motivated when many nodes have been deleted from the tree without further insertions. Rebalancing can then be forced to minimize lookup times, as deletion does not rebalance the tree.
@external(erlang, "gb_trees", "balance")
pub fn balance(tree: BalancedTree(k, v)) -> BalancedTree(k, v)

pub fn combine(
  tree: BalancedTree(k, v),
  other: BalancedTree(k, v),
  with fun: fn(v, v) -> v,
) -> BalancedTree(k, v) {
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

// filter
pub fn filter(
  in tree: BalancedTree(k, v),
  keeping predicate: fn(k, v) -> Bool,
) -> BalancedTree(k, v) {
  to_list(tree)
  |> list.filter(fn(kvp) { predicate(kvp.0, kvp.1) })
  |> from_list()
  |> balance()
}

pub fn fold(
  over tree: BalancedTree(k, v),
  from initial: acc,
  with fun: fn(acc, k, v) -> acc,
) -> acc {
  to_list(tree) |> list.fold(initial, fn(acc, kvp) { fun(acc, kvp.0, kvp.1) })
}

pub fn fold_right(
  over tree: BalancedTree(k, v),
  from initial: acc,
  with fun: fn(acc, k, v) -> acc,
) -> acc {
  to_list(tree)
  |> list.reverse()
  |> list.fold(initial, fn(acc, kvp) { fun(acc, kvp.0, kvp.1) })
}

/// Warning: this wraps gb_trees.from_orddict(List), which panics if there are duplicate keys in List
@external(erlang, "gb_trees", "from_orddict")
pub fn from_list(list: List(#(k, v))) -> BalancedTree(k, v)

pub fn get(from gb_tree: BalancedTree(k, v), get key: k) -> Result(v, Nil) {
  case gb_trees_lookup(key, gb_tree) {
    Value(v) -> Ok(v)
    None -> Error(Nil)
  }
}

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

@external(erlang, "gb_trees", "keys")
pub fn keys(tree: BalancedTree(k, v)) -> List(k)

pub fn map_values(
  in tree: BalancedTree(k, v),
  with fun: fn(k, v) -> a,
) -> BalancedTree(k, a) {
  gb_trees_map(fun, tree)
}

// merge

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

// take

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
