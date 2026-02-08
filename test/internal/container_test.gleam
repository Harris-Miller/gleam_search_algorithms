import balanced_map
import gleam/deque
import gleeunit
import gleeunit/should
import internal/search_container.{LIFOHeap, Queue, Stack, pop, push}

pub fn main() {
  gleeunit.main()
}

pub fn stack_push_test() {
  let stack = Stack([])
  let assert Stack(list) =
    stack |> push(#("a", 0)) |> push(#("b", 0)) |> push(#("c", 0))

  list |> should.equal(["c", "b", "a"])
}

pub fn stack_pop_test() {
  let stack = Stack(["a", "b", "c"])
  let assert Ok(#(a, stack)) = pop(stack)
  let assert Ok(#(b, stack)) = pop(stack)
  let assert Ok(#(c, stack)) = pop(stack)
  let err_from_empty = pop(stack)

  a.0 |> should.equal("a")
  b.0 |> should.equal("b")
  c.0 |> should.equal("c")
  err_from_empty |> should.be_error
}

pub fn queue_push_test() {
  let queue = Queue(deque.new())
  let assert Queue(queue) =
    queue |> push(#("a", 0)) |> push(#("b", 0)) |> push(#("c", 0))

  queue |> deque.to_list |> should.equal(["a", "b", "c"])
}

pub fn queue_pop_test() {
  let queue = Queue(deque.from_list(["a", "b", "c"]))
  let assert Ok(#(a, queue)) = pop(queue)
  let assert Ok(#(b, queue)) = pop(queue)
  let assert Ok(#(c, queue)) = pop(queue)
  let err_from_empty = pop(queue)

  a.0 |> should.equal("a")
  b.0 |> should.equal("b")
  c.0 |> should.equal("c")
  err_from_empty |> should.be_error
}

pub fn lifo_heap_push_test() {
  let balanced_map = balanced_map.new()
  let assert LIFOHeap(balanced_map) =
    LIFOHeap(balanced_map)
    |> push(#("a", 1))
    |> push(#("x", 2))
    |> push(#("b", 1))
    |> push(#("y", 2))

  let assert Ok(cost_1) = balanced_map.get(balanced_map, 1)
  let assert Ok(cost_2) = balanced_map.get(balanced_map, 2)

  cost_1 |> should.equal(["b", "a"])
  cost_2 |> should.equal(["y", "x"])
}

pub fn lifo_heap_pop_test() {
  let balanced_map = balanced_map.new()
  let heap =
    LIFOHeap(balanced_map)
    |> push(#("x", 2))
    |> push(#("a", 1))
    |> push(#("y", 2))
    |> push(#("b", 1))

  let assert Ok(#(b, heap)) = pop(heap)
  let assert Ok(#(a, heap)) = pop(heap)
  let assert Ok(#(y, heap)) = pop(heap)
  let assert Ok(#(x, heap)) = pop(heap)
  let err_from_empty = pop(heap)

  b |> should.equal(#("b", 1))
  a |> should.equal(#("a", 1))
  y |> should.equal(#("y", 2))
  x |> should.equal(#("x", 2))
  err_from_empty |> should.be_error
}
