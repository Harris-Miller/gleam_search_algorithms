import gleeunit
import gleeunit/should
import search_algorithms/internal/container

pub fn main() {
  gleeunit.main()
}

/// Simple test to verify LIFO behavior
pub fn stack_test() {
  let stack =
    container.new_stack()
    |> container.push(#(0, "c"))
    |> container.push(#(0, "b"))
    |> container.push(#(0, "a"))
  let assert Ok(#(a, stack)) = container.pop(stack)
  let assert Ok(#(b, stack)) = container.pop(stack)
  let assert Ok(#(c, stack)) = container.pop(stack)
  let err_from_empty = container.pop(stack)

  a.1 |> should.equal("a")
  b.1 |> should.equal("b")
  c.1 |> should.equal("c")
  err_from_empty |> should.be_error
}

/// Simple test to verify FIFO behavior
pub fn queue_test() {
  let queue =
    container.new_queue()
    |> container.push(#(0, "a"))
    |> container.push(#(0, "b"))
    |> container.push(#(0, "c"))

  let assert Ok(#(a, queue)) = container.pop(queue)
  let assert Ok(#(b, queue)) = container.pop(queue)
  let assert Ok(#(c, queue)) = container.pop(queue)
  let err_from_empty = container.pop(queue)

  a.1 |> should.equal("a")
  b.1 |> should.equal("b")
  c.1 |> should.equal("c")
  err_from_empty |> should.be_error
}

/// Test to verify LIFO in min-prioritized order
pub fn lifo_heap_test() {
  let heap =
    container.new_lifo_heap()
    |> container.push(#(2, "x"))
    |> container.push(#(1, "a"))
    |> container.push(#(1, "b"))
    |> container.push(#(2, "y"))

  let assert Ok(#(b, heap)) = container.pop(heap)
  let assert Ok(#(a, heap)) = container.pop(heap)
  let assert Ok(#(y, heap)) = container.pop(heap)
  let assert Ok(#(x, heap)) = container.pop(heap)
  let err_from_empty = container.pop(heap)

  b |> should.equal(#(1, "b"))
  a |> should.equal(#(1, "a"))
  y |> should.equal(#(2, "y"))
  x |> should.equal(#(2, "x"))
  err_from_empty |> should.be_error
}
