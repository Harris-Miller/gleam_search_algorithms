import gleam/deque.{type Deque}
import gleam/list
import gleam/option.{type Option}
import gleam/result

import balanced_map.{type BalancedMap}

pub type Container(value) {
  Stack(List(value))
  Queue(Deque(value))
  LIFOHeap(BalancedMap(Int, List(value)))
}

pub fn pop(
  sc: Container(value),
) -> Result(#(#(Int, value), Container(value)), Nil) {
  case sc {
    Stack(list) -> {
      case list {
        [head, ..tail] -> Ok(#(#(0, head), Stack(tail)))
        [] -> Error(Nil)
      }
    }
    Queue(deque) -> {
      deque.pop_front(deque)
      |> result.map(fn(tuple) {
        let #(value, deque) = tuple
        #(#(0, value), Queue(deque))
      })
    }
    LIFOHeap(tree) -> {
      case balanced_map.get_min(tree) {
        Error(Nil) -> Error(Nil)
        Ok(value) -> {
          case value {
            #(cost, [head]) -> {
              let next_heap = tree |> balanced_map.delete(cost) |> LIFOHeap()
              Ok(#(#(cost, head), next_heap))
            }
            #(cost, [head, ..tail]) -> {
              let next_heap =
                tree |> balanced_map.insert(cost, tail) |> LIFOHeap()
              Ok(#(#(cost, head), next_heap))
            }
            #(cost, []) -> {
              // logically, this should be unreachable
              // just in case, delete this min
              let next_heap = tree |> balanced_map.delete(cost) |> LIFOHeap()
              // and call pop again to get value at new min
              pop(next_heap)
            }
          }
        }
      }
    }
  }
}

pub fn push(
  container: Container(value),
  assoc: #(Int, value),
) -> Container(value) {
  let #(cost, value) = assoc
  case container {
    Stack(list) -> value |> list.prepend(list, _) |> Stack()
    Queue(queue) -> value |> deque.push_back(queue, _) |> Queue()
    LIFOHeap(tree) -> {
      let handler = fn(opt: Option(List(value))) {
        case opt {
          option.Some(list) -> [value, ..list]
          option.None -> [value]
        }
      }
      balanced_map.upsert(tree, cost, handler) |> LIFOHeap()
    }
  }
}
