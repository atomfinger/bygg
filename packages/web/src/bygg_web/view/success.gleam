import bygg_web/model.{type Model, type Msg, UserStartedOver}
import lustre/attribute.{attribute, class, href}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(model: Model, project_name: String) -> Element(Msg) {
  let _ = model
  html.div([class("max-w-lg mx-auto text-center py-8")], [
    html.div([class("text-6xl mb-6")], [html.text("🎉")]),
    html.h1([class("text-3xl font-bold text-stone-900 mb-3")], [
      html.text("Your project is ready!"),
    ]),
    html.p([class("text-stone-500 text-lg mb-2")], [
      html.text(project_name <> ".zip"),
      html.text(" is downloading now."),
    ]),
    html.p([class("text-stone-400 text-sm mb-10")], [
      html.text(
        "Unzip it and read the README inside for instructions on how to run your project.",
      ),
    ]),
    html.div([class("flex flex-col sm:flex-row gap-3 justify-center")], [
      html.button(
        [
          class(
            "px-6 py-2.5 rounded-full text-sm font-semibold bg-brand-500 text-white hover:bg-brand-600 cursor-pointer shadow-sm transition-colors",
          ),
          event.on_click(UserStartedOver),
        ],
        [html.text("Generate another project")],
      ),
      html.a(
        [
          class(
            "px-6 py-2.5 rounded-full text-sm font-semibold border border-stone-300 text-stone-600 hover:bg-stone-50 transition-colors",
          ),
          href("https://gleam.run/getting-started/"),
          attribute("target", "_blank"),
          attribute("rel", "noopener noreferrer"),
        ],
        [html.text("Gleam docs →")],
      ),
    ]),
  ])
}
