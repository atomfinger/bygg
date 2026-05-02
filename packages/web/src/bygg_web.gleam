import bygg_web/model
import bygg_web/update
import bygg_web/view/root
import lustre
import lustre/effect

pub fn main() {
  let app =
    lustre.application(
      fn(flags) { #(model.init(flags), effect.none()) },
      update.update,
      root.view,
    )
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}
