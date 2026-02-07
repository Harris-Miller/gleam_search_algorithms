import gleam/deque
import gleeunit
import gleeunit/should
import internal/search_container.{Queue, Stack, pop, push}

pub fn main() {
  gleeunit.main()
}

pub fn stack_push_test() {
  let stack = Stack([])
  let assert Stack(list) = stack |> push(1) |> push(2) |> push(3)

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
  let assert Queue(queue) = queue |> push(1) |> push(2) |> push(3)

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
