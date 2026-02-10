import gleeunit
import gleeunit/should
import internal/search_container

pub fn main() {
  gleeunit.main()
}

/// Simple test to verify LIFO behavior
pub fn stack_test() {
  let stack =
    search_container.new_stack()
    |> search_container.push(#(0, "c"))
    |> search_container.push(#(0, "b"))
    |> search_container.push(#(0, "a"))
  let assert Ok(#(a, stack)) = search_container.pop(stack)
  let assert Ok(#(b, stack)) = search_container.pop(stack)
  let assert Ok(#(c, stack)) = search_container.pop(stack)
  let err_from_empty = search_container.pop(stack)

  a.1 |> should.equal("a")
  b.1 |> should.equal("b")
  c.1 |> should.equal("c")
  err_from_empty |> should.be_error
}

/// Simple test to verify FIFO behavior
pub fn queue_test() {
  let queue =
    search_container.new_queue()
    |> search_container.push(#(0, "a"))
    |> search_container.push(#(0, "b"))
    |> search_container.push(#(0, "c"))

  let assert Ok(#(a, queue)) = search_container.pop(queue)
  let assert Ok(#(b, queue)) = search_container.pop(queue)
  let assert Ok(#(c, queue)) = search_container.pop(queue)
  let err_from_empty = search_container.pop(queue)

  a.1 |> should.equal("a")
  b.1 |> should.equal("b")
  c.1 |> should.equal("c")
  err_from_empty |> should.be_error
}

/// Test to verify LIFO in min-prioritized order
pub fn lifo_heap_test() {
  let heap =
    search_container.new_lifo_heap()
    |> search_container.push(#(2, "x"))
    |> search_container.push(#(1, "a"))
    |> search_container.push(#(1, "b"))
    |> search_container.push(#(2, "y"))

  let assert Ok(#(b, heap)) = search_container.pop(heap)
  let assert Ok(#(a, heap)) = search_container.pop(heap)
  let assert Ok(#(y, heap)) = search_container.pop(heap)
  let assert Ok(#(x, heap)) = search_container.pop(heap)
  let err_from_empty = search_container.pop(heap)

  b |> should.equal(#(1, "b"))
  a |> should.equal(#(1, "a"))
  y |> should.equal(#(2, "y"))
  x |> should.equal(#(2, "x"))
  err_from_empty |> should.be_error
}
