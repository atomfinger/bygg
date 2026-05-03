import bygg_web/model.{
  type Model, type Msg, ArchetypeTab, DepsTab, LandingTab, WizardTab,
}
import bygg_web/version
import bygg_web/view/archetype
import bygg_web/view/deps
import bygg_web/view/header
import bygg_web/view/landing
import bygg_web/view/shared
import bygg_web/view/success
import bygg_web/view/wizard
import gleam/option
import lustre/attribute.{attribute, class, href}
import lustre/element.{type Element}
import lustre/element/html

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("min-h-screen bg-stone-50 flex flex-col")], [
    header.render(model),
    html.main([class("flex-1 max-w-5xl mx-auto w-full px-4 py-8")], [
      active_panel(model),
    ]),
    footer(),
  ])
}

fn active_panel(model: Model) -> Element(Msg) {
  case model.last_generated {
    option.Some(name) -> success.render(model, name)
    option.None -> {
      let error = case model.generate_error {
        option.Some(err) -> shared.error_banner(err)
        option.None -> shared.nothing()
      }
      case model.active_tab {
        LandingTab -> landing.render(model)
        DepsTab -> html.div([], [error, deps.render(model)])
        ArchetypeTab -> html.div([], [error, archetype.render(model)])
        WizardTab -> html.div([], [error, wizard.render(model)])
      }
    }
  }
}

fn footer() -> Element(Msg) {
  html.footer([class("border-t border-stone-200 bg-white py-4 mt-8")], [
    html.div(
      [
        class(
          "max-w-5xl mx-auto px-4 flex flex-col gap-2 text-xs text-stone-400",
        ),
      ],
      [
        html.p([], [
          html.text(
            "Bygg is experimental. Generated projects are a starting point — review dependencies and configuration before use.",
          ),
        ]),
        html.div([class("flex items-center justify-between")], [
          html.span([], [
            html.text("Bygg v" <> version.version <> " — The Gleam Initializr"),
          ]),
          html.div([class("flex items-center gap-4")], [
            html.a(
              [
                class("hover:text-red-500 transition-colors"),
                href("https://github.com/lindbakk/bygg/issues/new"),
                attribute("target", "_blank"),
                attribute("rel", "noopener noreferrer"),
              ],
              [html.text("Report a problem")],
            ),
            html.a(
              [
                class("hover:text-brand-500 transition-colors"),
                href("https://github.com/lindbakk/bygg"),
                attribute("target", "_blank"),
                attribute("rel", "noopener noreferrer"),
              ],
              [html.text("GitHub")],
            ),
          ]),
        ]),
      ],
    ),
  ])
}
