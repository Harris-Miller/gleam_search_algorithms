import gleam/deque.{type Deque}
import gleam/list
import gleam/option.{type Option}
import gleam/result

import balanced_map.{type BalancedMap}

pub type Container(v) {
  Stack(List(v))
  Queue(Deque(v))
  LIFOHeap(BalancedMap(Int, List(v)))
}

pub fn pop(sc: Container(v)) -> Result(#(#(v, Int), Container(v)), Nil) {
  case sc {
    Stack(list) -> {
      case list {
        [head, ..tail] -> Ok(#(#(head, 0), Stack(tail)))
        [] -> Error(Nil)
      }
    }
    Queue(queue) -> {
      deque.pop_front(queue)
      |> result.map(fn(tuple) {
        let #(value, queue) = tuple
        #(#(value, 0), Queue(queue))
      })
    }
    LIFOHeap(tree) -> {
      case balanced_map.get_min(tree) {
        Error(Nil) -> Error(Nil)
        Ok(value) -> {
          case value {
            #(cost, [head]) -> {
              let next_heap = tree |> balanced_map.delete(cost) |> LIFOHeap()
              Ok(#(#(head, cost), next_heap))
            }
            #(cost, [head, ..tail]) -> {
              let next_heap =
                tree |> balanced_map.insert(cost, tail) |> LIFOHeap()
              Ok(#(#(head, cost), next_heap))
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

pub fn push(sc: Container(v), assoc: #(v, Int)) -> Container(v) {
  let #(value, cost) = assoc
  case sc {
    Stack(list) -> value |> list.prepend(list, _) |> Stack()
    Queue(queue) -> value |> deque.push_back(queue, _) |> Queue()
    LIFOHeap(tree) -> {
      let handler = fn(opt: Option(List(v))) {
        case opt {
          option.Some(list) -> [value, ..list]
          option.None -> [value]
        }
      }
      balanced_map.upsert(tree, cost, handler) |> LIFOHeap()
    }
  }
}
