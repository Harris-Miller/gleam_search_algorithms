import balanced_tree.{type BalancedTree}
import gleam/deque.{type Deque}
import gleam/list
import gleam/option.{type Option}
import gleam/result

pub opaque type SearchContainer(state) {
  Stack(List(#(Int, state)))
  Queue(Deque(#(Int, state)))
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

pub fn pop(
  sc: SearchContainer(state),
) -> Result(#(#(Int, state), SearchContainer(state)), Nil) {
  case sc {
    Stack(list) -> {
      case list {
        [head, ..tail] -> Ok(#(head, Stack(tail)))
        [] -> Error(Nil)
      }
    }
    Queue(deque) -> {
      deque
      |> deque.pop_front()
      |> result.map(fn(tuple) { #(tuple.0, Queue(tuple.1)) })
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

pub fn push(
  container: SearchContainer(value),
  cost_value_pair: #(Int, value),
) -> SearchContainer(value) {
  let #(cost, value) = cost_value_pair
  case container {
    Stack(list) -> list.prepend(list, cost_value_pair) |> Stack()
    Queue(queue) -> deque.push_back(queue, cost_value_pair) |> Queue()
    LIFOHeap(tree) -> {
      let handler = fn(opt: Option(List(value))) {
        case opt {
          option.Some(list) -> [value, ..list]
          option.None -> [value]
        }
      }
      balanced_tree.upsert(tree, cost, handler) |> LIFOHeap()
    }
  }
}
