import gleam/dict
import gleam/list
import gleam/string

pub fn make_grid(content: String) {
  content
  |> string.trim_end()
  |> string.split("\n")
  |> list.index_map(fn(line, row) {
    line
    |> string.split("")
    |> list.index_map(fn(value, col) { #(#(row, col), value) })
  })
  |> list.flatten()
  |> dict.from_list()
}

pub fn get_neighbors(p: #(Int, Int)) {
  [
    #(p.0 - 1, p.1),
    #(p.0, p.1 + 1),
    #(p.0 + 1, p.1),
    #(p.0, p.1 - 1),
  ]
}
