import gleam/deque
import gleeunit
import gleeunit/should
import search_algorithms/balanced_map
import search_algorithms/internal/container.{LIFOHeap, Queue, Stack, pop, push}

pub fn main() {
  gleeunit.main()
}

pub fn stack_push_test() {
  let stack = Stack([])
  let assert Stack(list) =
    stack |> push(#(0, "a")) |> push(#(0, "b")) |> push(#(0, "c"))

  list |> should.equal(["c", "b", "a"])
}

pub fn stack_pop_test() {
  let stack = Stack(["a", "b", "c"])
  let assert Ok(#(a, stack)) = pop(stack)
  let assert Ok(#(b, stack)) = pop(stack)
  let assert Ok(#(c, stack)) = pop(stack)
  let err_from_empty = pop(stack)

  a.1 |> should.equal("a")
  b.1 |> should.equal("b")
  c.1 |> should.equal("c")
  err_from_empty |> should.be_error
}

pub fn queue_push_test() {
  let queue = Queue(deque.new())
  let assert Queue(queue) =
    queue |> push(#(0, "a")) |> push(#(0, "b")) |> push(#(0, "c"))

  queue |> deque.to_list |> should.equal(["a", "b", "c"])
}

pub fn queue_pop_test() {
  let queue = Queue(deque.from_list(["a", "b", "c"]))
  let assert Ok(#(a, queue)) = pop(queue)
  let assert Ok(#(b, queue)) = pop(queue)
  let assert Ok(#(c, queue)) = pop(queue)
  let err_from_empty = pop(queue)

  a.1 |> should.equal("a")
  b.1 |> should.equal("b")
  c.1 |> should.equal("c")
  err_from_empty |> should.be_error
}

pub fn lifo_heap_push_test() {
  let balanced_map = balanced_map.new()
  let assert LIFOHeap(balanced_map) =
    LIFOHeap(balanced_map)
    |> push(#(1, "a"))
    |> push(#(2, "x"))
    |> push(#(1, "b"))
    |> push(#(2, "y"))

  let assert Ok(cost_1) = balanced_map.get(balanced_map, 1)
  let assert Ok(cost_2) = balanced_map.get(balanced_map, 2)

  cost_1 |> should.equal(["b", "a"])
  cost_2 |> should.equal(["y", "x"])
}

pub fn lifo_heap_pop_test() {
  let balanced_map = balanced_map.new()
  let heap =
    LIFOHeap(balanced_map)
    |> push(#(2, "x"))
    |> push(#(1, "a"))
    |> push(#(2, "y"))
    |> push(#(1, "b"))

  let assert Ok(#(b, heap)) = pop(heap)
  let assert Ok(#(a, heap)) = pop(heap)
  let assert Ok(#(y, heap)) = pop(heap)
  let assert Ok(#(x, heap)) = pop(heap)
  let err_from_empty = pop(heap)

  b |> should.equal(#(1, "b"))
  a |> should.equal(#(1, "a"))
  y |> should.equal(#(2, "y"))
  x |> should.equal(#(2, "x"))
  err_from_empty |> should.be_error
}
