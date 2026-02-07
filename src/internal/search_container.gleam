import gleam/deque.{type Deque}
import gleam/list
import gleam/result

// import internal/gb_tree.{type GbTree}

pub type SearchContainer(a) {
  Stack(List(a))
  Queue(Deque(a))
  // LIFOHeap(BalancedMap(Int, List(a)))
}

pub fn pop(sc: SearchContainer(a)) -> Result(#(a, SearchContainer(a)), Nil) {
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
  }
}

pub fn push(sc: SearchContainer(a), value: a) -> SearchContainer(a) {
  case sc {
    Stack(list) -> value |> list.prepend(list, _) |> Stack()
    Queue(queue) -> value |> deque.push_back(queue, _) |> Queue()
  }
}
