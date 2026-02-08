pub fn least_costly(left: List(#(Int, a)), right: List(#(Int, a))) -> Bool {
  case left, right {
    [#(cost_left, _), ..], [#(cost_right, _), ..] -> cost_right < cost_left
    // logically these will never happen
    [], _ -> False
    _, [] -> False
  }
}
