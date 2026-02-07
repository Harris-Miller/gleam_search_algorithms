import gleam/option

pub type GbTree(k, v)

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

@external(erlang, "gb_trees", "delete_any")
fn gb_trees_delete_any(key: k, gb_tree: GbTree(k, v)) -> GbTree(k, v)

pub fn delete(from tree: GbTree(k, v), delete key: k) -> GbTree(k, v) {
  gb_trees_delete_any(key, tree)
}

@external(erlang, "gb_trees", "get")
pub fn gb_trees_get(key: k, gb_tree: GbTree(k, v)) -> v

@external(erlang, "gb_trees", "enter")
fn gb_trees_enter(key: k, value: v, gb_tree: GbTree(k, v)) -> GbTree(k, v)

pub fn insert(
  into tree: GbTree(k, v),
  for key: k,
  insert value: v,
) -> GbTree(k, v) {
  gb_trees_enter(key, value, tree)
}

@external(erlang, "gb_trees", "lookup")
fn gb_trees_lookup(key: k, gb_tree: GbTree(k, v)) -> ErlangOption(v)

pub fn get(from gb_tree: GbTree(k, v), get key: k) -> Result(v, Nil) {
  case gb_trees_lookup(key, gb_tree) {
    Value(v) -> Ok(v)
    None -> Error(Nil)
  }
}

@external(erlang, "gb_trees", "empty")
pub fn new() -> GbTree(k, v)

@external(erlang, "gb_trees", "is_empty")
fn gb_trees_is_empty(tree: GbTree(k, v)) -> Bool

@external(erlang, "gb_trees", "smallest")
fn gb_trees_smallest(from tree: GbTree(k, v)) -> #(k, v)

// @external(erlang, "gb_trees", "take_smallest")
// fn gb_trees_take_smallest(from tree: GbTree(k, v)) -> #(k, v, GbTree(k, v))

@external(erlang, "gb_trees", "largest")
fn gb_trees_largest(from tree: GbTree(k, v)) -> #(k, v)

// @external(erlang, "gb_trees", "take_largest")
// fn gb_trees_take_largest(from tree: GbTree(k, v)) -> #(k, v, GbTree(k, v))

pub fn get_min(from tree: GbTree(k, v)) -> Result(#(k, v), Nil) {
  case gb_trees_is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_smallest() |> Ok()
  }
}

pub fn get_max(from tree: GbTree(k, v)) -> Result(#(k, v), Nil) {
  case gb_trees_is_empty(tree) {
    True -> Error(Nil)
    False -> tree |> gb_trees_largest() |> Ok()
  }
}

@external(erlang, "gb_trees", "to_list")
pub fn to_list(tree: GbTree(k, v)) -> List(#(k, v))

pub fn upsert(
  in tree: GbTree(k, v),
  update key: k,
  with fun: fn(option.Option(v)) -> v,
) -> GbTree(k, v) {
  get(tree, key)
  |> option.from_result()
  |> fun()
  |> gb_trees_enter(key, _, tree)
}
