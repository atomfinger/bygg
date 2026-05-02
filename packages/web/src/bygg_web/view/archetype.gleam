import bygg/archetype.{type Archetype}
import bygg/config.{type Target, Erlang, JavaScript}
import bygg_web/model.{
  type Model, type Msg, UserClickedGenerate, UserSelectedArchetype,
}
import bygg_web/view/shared
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(model: Model) -> Element(Msg) {
  html.div([class("flex flex-col gap-6")], [
    html.div([class("max-w-3xl")], [
      html.p([class("text-stone-500 text-sm mb-6")], [
        html.text(
          "Choose a preset that sets up a full project structure for a common use case.",
        ),
      ]),
      html.div(
        [class("grid grid-cols-1 sm:grid-cols-3 gap-4")],
        list.map(archetype.all, fn(arch) {
          arch_card(arch, model.selected_archetype == option.Some(arch.name))
        }),
      ),
    ]),
    generate_section(model),
  ])
}

fn arch_card(arch: Archetype, selected: Bool) -> Element(Msg) {
  let base =
    "cursor-pointer rounded-2xl border-2 p-5 transition-all hover:border-brand-400 hover:shadow-md"
  let state = case selected {
    True -> base <> " border-brand-500 bg-brand-50 shadow-sm"
    False -> base <> " border-stone-200 bg-white"
  }
  html.div([class(state), event.on_click(UserSelectedArchetype(arch.name))], [
    html.h3([class("font-bold text-stone-900 mb-1")], [
      html.text(arch_title(arch.name)),
    ]),
    html.p([class("text-xs text-stone-500 mb-3")], [
      html.text(arch.description),
    ]),
    html.div(
      [class("flex flex-wrap gap-1 mb-2")],
      list.map(arch.dependencies, fn(dep) {
        shared.pill(dep, "bg-stone-100 text-stone-600")
      }),
    ),
    shared.target_badge(target_label(arch.target), target_color(arch.target)),
  ])
}

fn generate_section(model: Model) -> Element(Msg) {
  case model.selected_archetype {
    option.None -> shared.nothing()
    option.Some(name) ->
      html.div(
        [
          class(
            "border-t border-stone-200 pt-5 flex items-center justify-between flex-wrap gap-4",
          ),
        ],
        [
          html.div([class("text-sm text-stone-600")], [
            html.text("Selected: "),
            html.span([class("font-semibold text-stone-900")], [
              html.text(arch_title(name)),
            ]),
          ]),
          html.button(
            [
              class(
                "px-6 py-2 rounded-full text-sm font-semibold bg-brand-500 text-white hover:bg-brand-600 cursor-pointer shadow-sm transition-colors",
              ),
              event.on_click(UserClickedGenerate),
            ],
            [html.text("Generate .zip")],
          ),
        ],
      )
  }
}

fn arch_title(name: String) -> String {
  case name {
    "rest-api" -> "REST API"
    "ssr-website" -> "SSR Website"
    "browser-app" -> "Browser App"
    _ -> string.capitalise(name)
  }
}

fn target_label(target: Target) -> String {
  case target {
    Erlang -> "Erlang / OTP"
    JavaScript -> "JavaScript"
  }
}

fn target_color(target: Target) -> String {
  case target {
    Erlang -> "bg-orange-100 text-orange-700"
    JavaScript -> "bg-yellow-100 text-yellow-700"
  }
}
