import gleam/deque.{type Deque}
import gleam/list
import gleam/option.{type Option}
import gleam/result

import internal/gb_tree.{type GbTree}

pub type SearchContainer(c, v) {
  Stack(List(v))
  Queue(Deque(v))
  LIFOHeap(GbTree(c, List(v)))
}

pub fn pop(
  sc: SearchContainer(c, v),
) -> Result(#(v, SearchContainer(c, v)), Nil) {
  case sc {
    Stack(list) -> {
      case list {
        [head, ..tail] -> Ok(#(head, Stack(tail)))
        [] -> Error(Nil)
      }
    }
    Queue(queue) -> {
      deque.pop_front(queue)
      |> result.map(fn(t) {
        let #(a, queue) = t
        #(a, Queue(queue))
      })
    }
    LIFOHeap(tree) -> {
      case gb_tree.get_min(tree) {
        Error(Nil) -> Error(Nil)
        Ok(value) -> {
          case value {
            #(cost, [head]) -> {
              let next_heap = tree |> gb_tree.delete(cost) |> LIFOHeap()
              Ok(#(head, next_heap))
            }
            #(cost, [head, ..tail]) -> {
              let next_heap = tree |> gb_tree.insert(cost, tail) |> LIFOHeap()
              Ok(#(head, next_heap))
            }
            #(cost, []) -> {
              // logically, this should be unreachable
              // just in case, delete this min
              let next_heap = tree |> gb_tree.delete(cost) |> LIFOHeap()
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
  sc: SearchContainer(c, v),
  cost: c,
  value: v,
) -> SearchContainer(c, v) {
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
      gb_tree.upsert(tree, cost, handler) |> LIFOHeap()
    }
  }
}
