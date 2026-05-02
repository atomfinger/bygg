import bygg/catalog.{
  type Category, Database, Http, Logging, Messaging, Serialization, Testing, Ui,
  Utilities,
}
import lustre/attribute.{type Attribute, attribute, class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn category_color(cat: Category) -> String {
  case cat {
    Http -> "bg-blue-100 text-blue-800"
    Database -> "bg-emerald-100 text-emerald-800"
    Testing -> "bg-purple-100 text-purple-800"
    Serialization -> "bg-yellow-100 text-yellow-800"
    Messaging -> "bg-rose-100 text-rose-800"
    Utilities -> "bg-stone-100 text-stone-700"
    Ui -> "bg-pink-100 text-pink-800"
    Logging -> "bg-orange-100 text-orange-800"
    _ -> "bg-stone-100 text-stone-700"
  }
}

pub fn pill(label: String, color: String) -> Element(a) {
  html.span(
    [
      class(
        "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium "
        <> color,
      ),
    ],
    [html.text(label)],
  )
}

pub fn card(
  attrs: List(Attribute(a)),
  children: List(Element(a)),
) -> Element(a) {
  html.div(
    [
      class("bg-white rounded-2xl shadow-sm border border-stone-200 p-5"),
      ..attrs
    ],
    children,
  )
}

pub fn radio_card(
  selected: Bool,
  on_click: a,
  title: String,
  description: String,
) -> Element(a) {
  let base =
    "cursor-pointer rounded-2xl border-2 p-4 transition-all hover:border-brand-400 hover:bg-brand-50"
  let state = case selected {
    True -> " border-brand-500 bg-brand-50 shadow-sm"
    False -> " border-stone-200 bg-white"
  }
  html.div([class(base <> state), event.on_click(on_click)], [
    html.div([class("flex items-center gap-2 mb-1")], [
      html.div(
        [
          class(
            "w-4 h-4 rounded-full border-2 flex items-center justify-center shrink-0 "
            <> case selected {
              True -> "border-brand-500"
              False -> "border-stone-300"
            },
          ),
        ],
        case selected {
          True -> [
            html.div([class("w-2 h-2 rounded-full bg-brand-500")], []),
          ]
          False -> []
        },
      ),
      html.span([class("font-semibold text-stone-900 text-sm")], [
        html.text(title),
      ]),
    ]),
    html.p([class("text-xs text-stone-500 ml-6")], [html.text(description)]),
  ])
}

pub fn section_label(text: String) -> Element(a) {
  html.p(
    [
      class(
        "text-xs font-semibold text-stone-400 uppercase tracking-wider mb-3",
      ),
    ],
    [html.text(text)],
  )
}

pub fn error_banner(msg: String) -> Element(a) {
  html.div(
    [
      class(
        "rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700 mt-4",
      ),
    ],
    [html.text(msg)],
  )
}

pub fn target_badge(label: String, color: String) -> Element(a) {
  html.span([class("text-xs font-medium px-1.5 py-0.5 rounded " <> color)], [
    html.text(label),
  ])
}

pub fn nothing() -> Element(a) {
  html.span([], [])
}

pub fn text_input(
  value: String,
  placeholder: String,
  on_input: fn(String) -> a,
  extra_class: String,
) -> Element(a) {
  html.input([
    attribute("type", "text"),
    attribute("value", value),
    attribute("placeholder", placeholder),
    event.on_input(on_input),
    class(
      "rounded-xl border border-stone-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent "
      <> extra_class,
    ),
  ])
}
