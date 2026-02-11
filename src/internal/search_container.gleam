import balanced_tree.{type BalancedTree}
import gleam/deque.{type Deque}
import gleam/list
import gleam/option.{type Option}
import gleam/result

/// SearchContainer abstracts away the data-structure used to store yet-to-visit states
/// Available constructors are
/// * `Stack` - for depth_first
/// * `Queue` - for breadth_first
/// * `LIFOHeap` - for dijkstra and a_star
/// All implement `push` and `pop`, allowing for generalized_search to not need to care about
/// how the order in which data is stored and retrieved
pub opaque type SearchContainer(state) {
  Stack(List(state))
  Queue(Deque(state))
  LIFOHeap(BalancedTree(Int, List(state)))
}

pub fn new_stack() {
  Stack([])
}

pub fn new_queue() {
  Queue(deque.new())
}

pub fn new_lifo_heap() {
  LIFOHeap(balanced_tree.new())
}

/// For `pop` to work for all SearchContainer constructors, the tuple `#(Int, state)` is used
/// `Stack` and `Queue` don't utilize these internally, and always set it to `0` in their returns
pub fn pop(
  search_container: SearchContainer(state),
) -> Result(#(#(Int, state), SearchContainer(state)), Nil) {
  case search_container {
    Stack(list) -> {
      case list {
        [head, ..tail] -> Ok(#(#(0, head), Stack(tail)))
        [] -> Error(Nil)
      }
    }
    Queue(deque) -> {
      deque
      |> deque.pop_front()
      |> result.map(fn(tuple) { #(#(0, tuple.0), Queue(tuple.1)) })
    }
    LIFOHeap(tree) -> {
      tree
      |> balanced_tree.get_min()
      |> result.try(fn(state) {
        case state {
          #(cost, [head]) -> {
            let next_heap = tree |> balanced_tree.delete(cost) |> LIFOHeap()
            Ok(#(#(cost, head), next_heap))
          }
          #(cost, [head, ..tail]) -> {
            let next_heap =
              tree |> balanced_tree.insert(cost, tail) |> LIFOHeap()
            Ok(#(#(cost, head), next_heap))
          }
          #(cost, []) -> {
            // logically, this should be unreachable, but just in case...
            // delete min
            let next_heap = tree |> balanced_tree.delete(cost) |> LIFOHeap()
            // and call pop again to get value at new min
            pop(next_heap)
          }
        }
      })
    }
  }
}

/// For `push` to work for all SearchContainer constructors, the tuple `#(Int, state)` is used
/// `Int` is only utilized by LIFOHeap, and represents "estimated remaining cost"
/// Effectively making it a Priority Queue
/// Stack and Queue ignore it
pub fn push(
  search_container: SearchContainer(state),
  cost_state_pair: #(Int, state),
) -> SearchContainer(state) {
  case search_container {
    Stack(list) -> list.prepend(list, cost_state_pair.1) |> Stack()
    Queue(queue) -> deque.push_back(queue, cost_state_pair.1) |> Queue()
    LIFOHeap(tree) -> {
      let #(cost, state) = cost_state_pair
      let handler = fn(opt: Option(List(state))) {
        case opt {
          option.Some(list) -> [state, ..list]
          option.None -> [state]
        }
      }
      balanced_tree.upsert(tree, cost, handler) |> LIFOHeap()
    }
  }
}
