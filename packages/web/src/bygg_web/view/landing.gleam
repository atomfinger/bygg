import bygg_web/model.{
  type Model, type Msg, ArchetypeTab, DepsTab, UserSwitchedTab, WizardTab,
}
import lustre/attribute.{attribute, class, src}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(_model: Model) -> Element(Msg) {
  html.div([class("max-w-3xl mx-auto text-center")], [
    html.img([
      src("/logo.png"),
      attribute("alt", "Bygg"),
      class("h-40 w-auto mx-auto mb-6"),
    ]),
    html.h1([class("text-3xl font-bold text-stone-900 mb-3")], [
      html.text("The Gleam Initializr"),
    ]),
    html.p([class("text-stone-500 text-lg mb-10 max-w-lg mx-auto")], [
      html.text(
        "Generate a Gleam project scaffold in seconds. Pick your dependencies, choose a preset, or follow the guided tour.",
      ),
    ]),
    html.div([class("flex flex-row gap-5 text-left")], [
      mode_card(
        "Pick your dependencies",
        "Choose individual packages from the catalog and assemble exactly what you need.",
        "Browse packages →",
        UserSwitchedTab(DepsTab),
      ),
      mode_card(
        "Use an Archetype",
        "Start from a preset template for REST APIs, SSR websites, or browser apps.",
        "View archetypes →",
        UserSwitchedTab(ArchetypeTab),
      ),
      mode_card(
        "Guided Tour",
        "Answer a few questions and we'll recommend the right setup for your project.",
        "Start the tour →",
        UserSwitchedTab(WizardTab),
      ),
    ]),
  ])
}

fn mode_card(
  title: String,
  description: String,
  cta: String,
  msg: Msg,
) -> Element(Msg) {
  html.div(
    [
      class(
        "flex-1 cursor-pointer rounded-2xl border-2 border-stone-200 bg-white p-6 hover:border-brand-400 hover:shadow-md transition-all group flex flex-col",
      ),
      event.on_click(msg),
    ],
    [
      html.h2([class("font-bold text-stone-900 text-lg mb-2")], [
        html.text(title),
      ]),
      html.p([class("text-sm text-stone-500 mb-4 flex-1")], [
        html.text(description),
      ]),
      html.span(
        [
          class(
            "text-sm font-semibold text-brand-500 group-hover:text-brand-600",
          ),
        ],
        [html.text(cta)],
      ),
    ],
  )
}
