import bygg_web/model.{
  type Model, type Msg, ArchetypeTab, DepsTab, LandingTab, UserSetProjectName,
  UserSwitchedTab, WizardTab,
}
import gleam/option
import lustre/attribute.{attribute, class, src}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(model: Model) -> Element(Msg) {
  case model.active_tab, model.last_generated {
    LandingTab, _ -> html.span([], [])
    _, option.Some(_) -> html.span([], [])
    _, option.None ->
      html.header(
        [class("bg-white border-b border-stone-200 sticky top-0 z-10")],
        [
          html.div([class("max-w-5xl mx-auto px-4")], [
            top_row(model),
            tabs_row(model),
          ]),
        ],
      )
  }
}

fn top_row(model: Model) -> Element(Msg) {
  html.div([class("py-3 flex items-center gap-6")], [
    html.img([
      src("/logo.png"),
      attribute("alt", "Bygg"),
      class("h-20 w-auto cursor-pointer shrink-0"),
      event.on_click(UserSwitchedTab(LandingTab)),
    ]),
    html.div([class("flex flex-col gap-1")], [
      html.label(
        [class("text-xs font-semibold text-stone-500 uppercase tracking-wide")],
        [html.text("Project name")],
      ),
      html.input([
        attribute("type", "text"),
        attribute("value", model.project_name),
        attribute("placeholder", "my_app"),
        event.on_input(UserSetProjectName),
        class(
          "w-56 rounded-xl border-2 border-brand-300 px-4 py-2.5 text-base font-medium text-stone-900 placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-brand-400",
        ),
      ]),
    ]),
  ])
}

fn tabs_row(model: Model) -> Element(Msg) {
  let tab_class = fn(active: Bool) {
    let base =
      "px-4 py-2 text-sm font-medium border-b-2 transition-colors cursor-pointer -mb-px"
    case active {
      True -> base <> " border-brand-500 text-brand-600"
      False ->
        base
        <> " border-transparent text-stone-500 hover:text-stone-700 hover:border-stone-300"
    }
  }
  html.nav([class("flex border-b border-stone-200")], [
    html.button(
      [
        class(tab_class(model.active_tab == DepsTab)),
        event.on_click(UserSwitchedTab(DepsTab)),
      ],
      [html.text("Dependencies")],
    ),
    html.button(
      [
        class(tab_class(model.active_tab == ArchetypeTab)),
        event.on_click(UserSwitchedTab(ArchetypeTab)),
      ],
      [html.text("Archetypes")],
    ),
    html.button(
      [
        class(tab_class(model.active_tab == WizardTab)),
        event.on_click(UserSwitchedTab(WizardTab)),
      ],
      [html.text("Guided Tour")],
    ),
  ])
}
