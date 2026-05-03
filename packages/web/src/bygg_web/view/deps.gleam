import bygg/catalog.{
  type Category, type Package, BothTargets, Ci, ErlangOnly, FrontendFramework,
  HttpServer, JavaScriptOnly, LustreComponent, LustreServerComponent,
  WebFramework,
}
import bygg/config.{Erlang, JavaScript}
import bygg_web/model.{
  type Model, type Msg, UserClickedGenerate, UserFilteredCategory, UserSetTarget,
  UserToggledDep,
}
import bygg_web/view/shared
import gleam/list
import gleam/option
import gleam/set
import lustre/attribute.{attribute, class, href}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(model: Model) -> Element(Msg) {
  html.div([class("flex flex-col gap-6")], [
    html.div([class("flex gap-6 min-h-0")], [
      category_sidebar(model),
      package_grid(model),
    ]),
    generate_section(model),
  ])
}

fn category_sidebar(model: Model) -> Element(Msg) {
  let all_pkgs = catalog.for_target(model.target)
  let visible_categories =
    catalog.all_categories()
    |> list.filter(fn(cat) {
      list.any(all_pkgs, fn(p) {
        !p.is_hidden && !p.is_disabled && p.category == cat
      })
    })
  html.aside([class("w-44 shrink-0 flex flex-col gap-1 pt-1")], [
    target_selector(model),
    html.div([class("h-px bg-stone-200 my-2")], []),
    shared.section_label("Categories"),
    category_btn(option.None, model.active_category),
    ..list.map(visible_categories, fn(cat) {
      category_btn(option.Some(cat), model.active_category)
    })
  ])
}

fn category_btn(
  cat: option.Option(Category),
  active: option.Option(Category),
) -> Element(Msg) {
  let label = case cat {
    option.None -> "All"
    option.Some(c) -> catalog.category_label(c)
  }
  let is_active = cat == active
  let base =
    "text-left px-3 py-1.5 rounded-xl text-sm font-medium transition-colors cursor-pointer w-full"
  let state = case is_active {
    True -> base <> " bg-brand-100 text-brand-700"
    False -> base <> " text-stone-600 hover:bg-stone-100"
  }
  html.button([class(state), event.on_click(UserFilteredCategory(cat))], [
    html.text(label),
  ])
}

fn package_grid(model: Model) -> Element(Msg) {
  let all_pkgs = catalog.for_target(model.target)
  let visible =
    all_pkgs
    |> list.filter(fn(p) { !p.is_hidden && !p.is_disabled })
    |> list.filter(fn(p) {
      case model.active_category {
        option.None -> True
        option.Some(cat) -> p.category == cat
      }
    })

  case visible {
    [] ->
      html.div(
        [
          class(
            "flex-1 flex items-center justify-center text-stone-400 text-sm",
          ),
        ],
        [html.text("No packages in this category for the selected target.")],
      )
    pkgs ->
      html.div([class("flex-1 flex flex-col gap-3")], [
        html.div(
          [class("grid grid-cols-1 sm:grid-cols-2 gap-3 content-start")],
          list.map(pkgs, fn(pkg) { package_card(pkg, model) }),
        ),
        html.p([class("text-xs text-stone-400 pt-1")], [
          html.text("Didn't find what you need? Check out the "),
          html.a(
            [
              class("text-brand-500 hover:underline"),
              href("https://packages.gleam.run/"),
              attribute("target", "_blank"),
              attribute("rel", "noopener noreferrer"),
            ],
            [html.text("Gleam package registry")],
          ),
          html.text("."),
        ]),
      ])
  }
}

fn package_card(pkg: Package, model: Model) -> Element(Msg) {
  let selected = set.contains(model.selected_deps, pkg.name)
  let usable = package_compat(pkg, model) && !role_conflict(pkg, model)
  let outer_border = case usable {
    True ->
      case selected {
        True -> " border-brand-400 bg-brand-50"
        False -> " border-stone-200 bg-white hover:border-stone-300"
      }
    False -> " border-stone-100 bg-stone-50 opacity-50"
  }
  html.div([class("rounded-2xl border-2 transition-all" <> outer_border)], [
    html.div(
      [
        class(
          "p-4 select-none"
          <> case usable {
            True -> " cursor-pointer"
            False -> " cursor-not-allowed"
          },
        ),
        ..case usable {
          True -> [event.on_click(UserToggledDep(pkg.name))]
          False -> []
        }
      ],
      [
        html.div([class("flex items-start justify-between gap-2 mb-1")], [
          html.div([class("flex items-center gap-2 flex-wrap")], [
            html.span([class("font-semibold text-sm text-stone-900")], [
              html.text(pkg.name),
            ]),
            shared.pill(
              catalog.category_label(pkg.category),
              shared.category_color(pkg.category),
            ),
            target_label(pkg),
          ]),
          checkbox(selected),
        ]),
        html.p([class("text-xs text-stone-500 mt-1")], [
          html.text(pkg.description),
        ]),
      ],
    ),
    html.div([class("px-4 pb-3 border-t border-stone-100 pt-2")], [
      html.a(
        [
          class("text-xs text-brand-500 hover:text-brand-600 hover:underline"),
          href(pkg.repository),
          attribute("target", "_blank"),
          attribute("rel", "noopener noreferrer"),
        ],
        [
          html.text(case pkg.category {
            Ci -> "Read more →"
            _ -> "View repository →"
          }),
        ],
      ),
    ]),
  ])
}

fn target_label(pkg: Package) -> Element(Msg) {
  case pkg.targets {
    ErlangOnly ->
      shared.target_badge("Erlang only", "bg-orange-100 text-orange-700")
    JavaScriptOnly ->
      shared.target_badge("JS only", "bg-yellow-100 text-yellow-700")
    BothTargets -> shared.nothing()
  }
}

fn target_selector(model: Model) -> Element(Msg) {
  let btn = fn(label, target) {
    let active = model.target == target
    let base =
      "w-full text-left px-3 py-1.5 rounded-xl text-sm font-medium transition-colors cursor-pointer"
    let state = case active {
      True -> base <> " bg-brand-100 text-brand-700"
      False -> base <> " text-stone-600 hover:bg-stone-100"
    }
    html.button([class(state), event.on_click(UserSetTarget(target))], [
      html.text(label),
    ])
  }
  html.div([class("flex flex-col gap-1")], [
    shared.section_label("Target"),
    btn("Erlang", Erlang),
    btn("JavaScript", JavaScript),
  ])
}

fn checkbox(checked: Bool) -> Element(Msg) {
  let base =
    "w-5 h-5 rounded-md border-2 shrink-0 flex items-center justify-center transition-colors"
  let state = case checked {
    True -> base <> " border-brand-500 bg-brand-500"
    False -> base <> " border-stone-300"
  }
  html.div([class(state)], case checked {
    True -> [
      html.span([class("text-white text-xs font-bold leading-none")], [
        html.text("✓"),
      ]),
    ]
    False -> []
  })
}

fn package_compat(pkg: Package, model: Model) -> Bool {
  case pkg.targets, model.target {
    ErlangOnly, Erlang -> True
    JavaScriptOnly, config.JavaScript -> True
    BothTargets, _ -> True
    _, _ -> False
  }
}

fn role_conflict(pkg: Package, model: Model) -> Bool {
  case set.contains(model.selected_deps, pkg.name) {
    True -> False
    False -> {
      let current = catalog.roles_for(set.to_list(model.selected_deps))
      let combined = list.append(current, pkg.roles)
      let framework_count =
        list.count(combined, fn(r) {
          r == FrontendFramework
          || r == LustreComponent
          || r == LustreServerComponent
        })
      let has_frontend = list.contains(combined, FrontendFramework)
      let has_web =
        list.contains(combined, WebFramework)
        || list.contains(combined, HttpServer)
      framework_count > 1 || { has_frontend && has_web }
    }
  }
}

fn generate_section(model: Model) -> Element(Msg) {
  let names = set.to_list(model.selected_deps)
  case names {
    [] -> shared.nothing()
    _ ->
      html.div(
        [
          class(
            "border-t border-stone-200 pt-5 flex items-center justify-between flex-wrap gap-4",
          ),
        ],
        [
          html.div(
            [class("flex flex-wrap gap-1.5")],
            list.map(names, fn(name) {
              html.span(
                [
                  class(
                    "px-2.5 py-1 rounded-full bg-brand-100 text-brand-700 text-xs font-medium",
                  ),
                ],
                [html.text(name)],
              )
            }),
          ),
          html.button(
            [
              class(
                "px-6 py-2 rounded-full text-sm font-semibold bg-brand-500 text-white hover:bg-brand-600 cursor-pointer shadow-sm transition-colors whitespace-nowrap",
              ),
              event.on_click(UserClickedGenerate),
            ],
            [html.text("Generate .zip")],
          ),
        ],
      )
  }
}
