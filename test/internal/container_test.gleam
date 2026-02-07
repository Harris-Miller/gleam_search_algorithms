import gleam/deque
import gleeunit
import gleeunit/should
import internal/container.{LIFOHeap, Queue, Stack, pop, push}
import internal/gb_tree as gb

pub fn main() {
  gleeunit.main()
}

pub fn stack_push_test() {
  let stack = Stack([])
  let assert Stack(list) = stack |> push(Nil, 1) |> push(Nil, 2) |> push(Nil, 3)

  list |> should.equal([3, 2, 1])
}

pub fn stack_pop_test() {
  let stack = Stack([3, 2, 1])
  let assert Ok(#(a, stack)) = pop(stack)
  let assert Ok(#(b, stack)) = pop(stack)
  let assert Ok(#(c, stack)) = pop(stack)
  let err_from_empty = pop(stack)

  a |> should.equal(3)
  b |> should.equal(2)
  c |> should.equal(1)
  err_from_empty |> should.be_error
}

pub fn queue_push_test() {
  let queue = Queue(deque.new())
  let assert Queue(queue) =
    queue |> push(Nil, 1) |> push(Nil, 2) |> push(Nil, 3)

  queue |> deque.to_list |> should.equal([1, 2, 3])
}

pub fn queue_pop_test() {
  let queue = Queue(deque.from_list([1, 2, 3]))
  let assert Ok(#(a, queue)) = pop(queue)
  let assert Ok(#(b, queue)) = pop(queue)
  let assert Ok(#(c, queue)) = pop(queue)
  let err_from_empty = pop(queue)

  a |> should.equal(1)
  b |> should.equal(2)
  c |> should.equal(3)
  err_from_empty |> should.be_error
}

pub fn lifo_heap_push_test() {
  let gb_tree = gb.new()
  let assert LIFOHeap(gb_tree) =
    LIFOHeap(gb_tree)
    |> push(1, "a")
    |> push(2, "x")
    |> push(1, "b")
    |> push(2, "y")

  let assert Ok(cost_1) = gb.get(gb_tree, 1)
  let assert Ok(cost_2) = gb.get(gb_tree, 2)

  cost_1 |> should.equal(["b", "a"])
  cost_2 |> should.equal(["y", "x"])
}

pub fn lifo_heap_pop_test() {
  let gb_tree = gb.new()
  let heap =
    LIFOHeap(gb_tree)
    |> push(2, "x")
    |> push(1, "a")
    |> push(2, "y")
  // |> push(1, "b")

  // let assert Ok(#(b, heap)) = pop(heap)
  let assert Ok(#(a, heap)) = pop(heap)
  let assert Ok(#(y, heap)) = pop(heap)
  let assert Ok(#(x, heap)) = pop(heap)
  let err_from_empty = pop(heap)

  // b |> should.equal("b")
  a |> should.equal("a")
  y |> should.equal("y")
  x |> should.equal("x")
  err_from_empty |> should.be_error
}
