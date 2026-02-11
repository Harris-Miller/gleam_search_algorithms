import gleam/list
import gleeunit
import gleeunit/should
import search_algorithms

pub fn main() {
  gleeunit.main()
}

type Tree(a) {
  Branch(a, List(Tree(a)))
  Leaf(a)
}

const tree: Tree(String) = Branch(
  "1",
  [
    Branch("11", [Leaf("111"), Leaf("112")]),
    Branch("12", [Leaf("121"), Leaf("122")]),
  ],
)

// test('search function', () => {
//   const next = ({ children }: Tree<string>) => children;
//   const found = ({ value }: Tree<string>) => value === '122';

//   const searchResults = depthFirstSearch(next, found, tree)?.path.map(x => x.value);

//   expect(searchResults).toEqual(['1', '12', '122']);
// });
pub fn depth_first_test() {
  let next = fn(state: Tree(a)) -> List(Tree(a)) {
    case state {
      Leaf(_) -> []
      Branch(_, sub_tree) -> sub_tree
    }
  }

  let found = fn(state: Tree(String)) -> Bool {
    case state {
      Leaf(value) -> value == "122"
      Branch(value, _) -> value == "122"
    }
  }

  let assert Ok(search_result) =
    search_algorithms.depth_first(next, found, tree)

  let value_list =
    list.map(search_result, fn(tree: Tree(String)) {
      case tree {
        Leaf(a) -> a
        Branch(a, _) -> a
      }
    })

  value_list |> should.equal(["12", "122"])
}
