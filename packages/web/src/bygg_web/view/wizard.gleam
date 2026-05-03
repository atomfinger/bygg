import bygg/config.{Erlang, JavaScript}
import bygg_web/model.{
  type Model, type Msg, AskCi, AskDatabase, AskMessaging, AskPurpose, AskTesting,
  WizardAnsweredPurpose, WizardApply, WizardBack, WizardChoseCi,
  WizardChoseDatabase, WizardChoseMessaging, WizardContinued, WizardDone,
  WizardToggledTestTool,
}
import bygg_web/view/shared
import gleam/list
import gleam/option
import gleam/set
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(model: Model) -> Element(Msg) {
  html.div([class("max-w-2xl mx-auto")], [
    step_indicator(model),
    html.div([class("mt-8")], [step_content(model)]),
  ])
}

fn step_indicator(model: Model) -> Element(Msg) {
  let steps = case model.purpose {
    option.Some("rest-api") | option.Some("ssr-website") -> [
      "Purpose", "Database", "Messaging", "Testing", "CI", "Done",
    ]
    option.Some(_) -> ["Purpose", "CI", "Done"]
    option.None -> ["Purpose", "CI", "Done"]
  }
  let current_idx = case model.wizard_step {
    AskPurpose -> 0
    AskDatabase -> 1
    AskMessaging -> 2
    AskTesting -> 3
    AskCi ->
      case model.purpose {
        option.Some("rest-api") | option.Some("ssr-website") -> 4
        _ -> 1
      }
    WizardDone ->
      case model.purpose {
        option.Some("rest-api") | option.Some("ssr-website") -> 5
        _ -> 2
      }
  }
  html.div(
    [class("flex items-center gap-2")],
    list.index_map(steps, fn(label, i) {
      let is_done = i < current_idx
      let is_active = i == current_idx
      let dot_class =
        "w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold shrink-0 "
        <> case is_active, is_done {
          True, _ -> "bg-brand-500 text-white"
          False, True -> "bg-brand-200 text-brand-700"
          False, False -> "bg-stone-200 text-stone-500"
        }
      let label_class =
        "text-xs font-medium "
        <> case is_active {
          True -> "text-brand-600"
          False -> "text-stone-400"
        }
      let connector = case i < list.length(steps) - 1 {
        True -> [
          html.div(
            [
              class(
                "flex-1 h-0.5 "
                <> case i < current_idx {
                  True -> "bg-brand-300"
                  False -> "bg-stone-200"
                },
              ),
            ],
            [],
          ),
        ]
        False -> []
      }
      html.div(
        [
          class(
            "flex items-center gap-2 "
            <> case i < list.length(steps) - 1 {
              True -> "flex-1"
              False -> ""
            },
          ),
        ],
        [
          html.div([class("flex flex-col items-center gap-1")], [
            html.div([class(dot_class)], [html.text(int_to_string(i + 1))]),
            html.span([class(label_class)], [html.text(label)]),
          ]),
          ..connector
        ],
      )
    }),
  )
}

fn step_content(model: Model) -> Element(Msg) {
  case model.wizard_step {
    AskPurpose -> ask_purpose(model)
    AskDatabase -> ask_database(model)
    AskMessaging -> ask_messaging(model)
    AskTesting -> ask_testing(model)
    AskCi -> ask_ci(model)
    WizardDone -> wizard_done(model)
  }
}

fn ask_purpose(model: Model) -> Element(Msg) {
  let choices = [
    #("rest-api", "REST API", "JSON web service with Wisp + Mist", Erlang),
    #("ssr-website", "SSR Website", "Server-rendered HTML with Lustre", Erlang),
    #("browser-app", "Browser App", "Client-side SPA with Lustre", JavaScript),
  ]
  html.div([], [
    html.h2([class("text-xl font-bold text-stone-900 mb-2")], [
      html.text("What are you building?"),
    ]),
    html.p([class("text-stone-500 text-sm mb-6")], [
      html.text("Pick the type of project that best describes your goal."),
    ]),
    html.div(
      [class("grid grid-cols-1 sm:grid-cols-2 gap-3")],
      list.map(choices, fn(choice) {
        let #(key, title, desc, target) = choice
        purpose_card(
          model.purpose == option.Some(key),
          WizardAnsweredPurpose(key),
          title,
          desc,
          target,
        )
      }),
    ),
  ])
}

fn purpose_card(
  selected: Bool,
  msg: Msg,
  title: String,
  description: String,
  target: config.Target,
) -> Element(Msg) {
  let #(target_label, target_color) = case target {
    Erlang -> #("Erlang / OTP", "bg-orange-100 text-orange-700")
    JavaScript -> #("JavaScript", "bg-yellow-100 text-yellow-700")
  }
  let base =
    "cursor-pointer rounded-2xl border-2 p-4 transition-all hover:border-brand-400 hover:bg-brand-50"
  let state = case selected {
    True -> " border-brand-500 bg-brand-50 shadow-sm"
    False -> " border-stone-200 bg-white"
  }
  html.div([class(base <> state), event.on_click(msg)], [
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
          True -> [html.div([class("w-2 h-2 rounded-full bg-brand-500")], [])]
          False -> []
        },
      ),
      html.span([class("font-semibold text-stone-900 text-sm")], [
        html.text(title),
      ]),
      shared.target_badge(target_label, target_color),
    ]),
    html.p([class("text-xs text-stone-500 ml-6")], [html.text(description)]),
  ])
}

fn ask_database(model: Model) -> Element(Msg) {
  let choices = [
    #(
      option.Some("pog"),
      "PostgreSQL",
      "pog — battle-tested Postgres client for Erlang/OTP",
    ),
    #(
      option.Some("sqlight"),
      "SQLite",
      "sqlight — embedded SQLite, zero infra needed",
    ),
    #(
      option.Some("shork"),
      "MySQL / MariaDB",
      "shork — MySQL client for Erlang/OTP",
    ),
  ]
  html.div([], [
    html.h2([class("text-xl font-bold text-stone-900 mb-2")], [
      html.text("Does your app need a database?"),
    ]),
    html.p([class("text-stone-500 text-sm mb-6")], [
      html.text(
        "Select one to include it in your project, or skip to continue without.",
      ),
    ]),
    html.div(
      [class("grid grid-cols-1 sm:grid-cols-2 gap-3")],
      list.map(choices, fn(choice) {
        let #(key, title, desc) = choice
        shared.radio_card(
          model.db_choice == key,
          WizardChoseDatabase(key),
          title,
          desc,
        )
      }),
    ),
    nav_row([back_btn(), skip_btn(WizardChoseDatabase(option.None))]),
  ])
}

fn ask_messaging(model: Model) -> Element(Msg) {
  let choices = [
    #(
      option.Some("franz"),
      "Apache Kafka",
      "franz — high-throughput event streaming for Erlang",
    ),
    #(
      option.Some("carotte"),
      "RabbitMQ",
      "carotte — AMQP messaging for Erlang/OTP",
    ),
  ]
  html.div([], [
    html.h2([class("text-xl font-bold text-stone-900 mb-2")], [
      html.text("Does your app need messaging?"),
    ]),
    html.p([class("text-stone-500 text-sm mb-6")], [
      html.text("Select a messaging system or skip."),
    ]),
    html.div(
      [class("grid grid-cols-1 sm:grid-cols-2 gap-3")],
      list.map(choices, fn(choice) {
        let #(key, title, desc) = choice
        shared.radio_card(
          model.msg_choice == key,
          WizardChoseMessaging(key),
          title,
          desc,
        )
      }),
    ),
    nav_row([back_btn(), skip_btn(WizardChoseMessaging(option.None))]),
  ])
}

fn ask_testing(model: Model) -> Element(Msg) {
  let tools = case model.purpose {
    option.Some("rest-api") | option.Some("ssr-website") -> [
      #(
        "testcontainers_gleam",
        "testcontainers",
        "Spin up Docker containers (Postgres, etc.) in your tests",
      ),
    ]
    _ -> []
  }
  html.div([], [
    html.h2([class("text-xl font-bold text-stone-900 mb-2")], [
      html.text("Any testing tools?"),
    ]),
    html.p([class("text-stone-500 text-sm mb-6")], [
      html.text("Select as many as you like, or skip."),
    ]),
    html.div(
      [class("grid grid-cols-1 sm:grid-cols-2 gap-3")],
      list.map(tools, fn(tool) {
        let #(key, title, desc) = tool
        let selected = set.contains(model.test_choices, key)
        test_toggle(selected, WizardToggledTestTool(key), title, desc)
      }),
    ),
    nav_row([back_btn(), continue_btn()]),
  ])
}

fn ask_ci(model: Model) -> Element(Msg) {
  let choices = [
    #(
      option.Some("github_actions"),
      "GitHub Actions",
      "Generate .github/workflows/ci.yml",
    ),
    #(option.Some("gitlab_ci"), "GitLab CI/CD", "Generate .gitlab-ci.yml"),
    #(option.Some("circleci"), "CircleCI", "Generate .circleci/config.yml"),
    #(option.Some("travisci"), "Travis CI", "Generate .travis.yml"),
  ]
  html.div([], [
    html.h2([class("text-xl font-bold text-stone-900 mb-2")], [
      html.text("Set up CI?"),
    ]),
    html.p([class("text-stone-500 text-sm mb-6")], [
      html.text("Select a CI provider or skip to continue without one."),
    ]),
    html.div(
      [class("grid grid-cols-1 sm:grid-cols-2 gap-3")],
      list.map(choices, fn(choice) {
        let #(key, title, desc) = choice
        shared.radio_card(
          model.ci_choice == key,
          WizardChoseCi(key),
          title,
          desc,
        )
      }),
    ),
    nav_row([back_btn(), skip_btn(WizardChoseCi(option.None))]),
  ])
}

fn wizard_done(model: Model) -> Element(Msg) {
  let purpose_label = case model.purpose {
    option.Some("rest-api") -> "REST API"
    option.Some("ssr-website") -> "SSR Website"
    option.Some("browser-app") -> "Browser App"
    _ -> "Custom"
  }
  html.div([], [
    html.h2([class("text-xl font-bold text-stone-900 mb-2")], [
      html.text("Ready to generate!"),
    ]),
    html.p([class("text-stone-500 text-sm mb-6")], [
      html.text("Here's what will be included in your project."),
    ]),
    html.div(
      [class("bg-white rounded-2xl border border-stone-200 p-5 space-y-3")],
      [
        summary_row("Project type", purpose_label),
        case model.db_choice {
          option.Some(db) -> summary_row("Database", db)
          option.None -> shared.nothing()
        },
        case model.msg_choice {
          option.Some(m) -> summary_row("Messaging", m)
          option.None -> shared.nothing()
        },
        ..list.append(
          list.map(set.to_list(model.test_choices), fn(t) {
            summary_row("Testing", t)
          }),
          case model.ci_choice {
            option.Some(ci) -> [summary_row("CI", ci)]
            option.None -> []
          },
        )
      ],
    ),
    html.div([class("flex gap-3 mt-6")], [
      back_btn(),
      html.button(
        [
          class(
            "px-6 py-2 rounded-xl text-sm font-semibold bg-brand-500 text-white hover:bg-brand-600 cursor-pointer shadow-sm",
          ),
          event.on_click(WizardApply),
        ],
        [html.text("Generate .zip →")],
      ),
    ]),
  ])
}

fn test_toggle(
  selected: Bool,
  msg: Msg,
  title: String,
  description: String,
) -> Element(Msg) {
  let base =
    "cursor-pointer rounded-2xl border-2 p-4 transition-all hover:border-brand-400 hover:bg-brand-50"
  let state = case selected {
    True -> " border-brand-500 bg-brand-50 shadow-sm"
    False -> " border-stone-200 bg-white"
  }
  html.div([class(base <> state), event.on_click(msg)], [
    html.div([class("flex items-center gap-2 mb-1")], [
      html.div(
        [
          class(
            "w-4 h-4 rounded border-2 flex items-center justify-center shrink-0 "
            <> case selected {
              True -> "border-brand-500 bg-brand-500"
              False -> "border-stone-300"
            },
          ),
        ],
        case selected {
          True -> [
            html.span([class("text-white text-xs font-bold leading-none")], [
              html.text("✓"),
            ]),
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

fn summary_row(label: String, value: String) -> Element(Msg) {
  html.div([class("flex items-center justify-between text-sm")], [
    html.span([class("text-stone-500")], [html.text(label)]),
    html.span(
      [class("font-medium text-stone-900 bg-stone-100 px-2 py-0.5 rounded-lg")],
      [html.text(value)],
    ),
  ])
}

fn nav_row(buttons: List(Element(Msg))) -> Element(Msg) {
  html.div([class("flex gap-3 mt-6")], buttons)
}

fn back_btn() -> Element(Msg) {
  html.button(
    [
      class(
        "px-4 py-2 rounded-xl text-sm font-medium text-stone-600 border border-stone-300 hover:bg-stone-50 cursor-pointer",
      ),
      event.on_click(WizardBack),
    ],
    [html.text("Back")],
  )
}

fn skip_btn(msg: Msg) -> Element(Msg) {
  html.button(
    [
      class(
        "px-4 py-2 rounded-xl text-sm font-medium text-stone-500 hover:text-stone-700 cursor-pointer",
      ),
      event.on_click(msg),
    ],
    [html.text("Skip →")],
  )
}

fn continue_btn() -> Element(Msg) {
  html.button(
    [
      class(
        "px-5 py-2 rounded-xl text-sm font-semibold bg-brand-500 text-white hover:bg-brand-600 cursor-pointer shadow-sm",
      ),
      event.on_click(WizardContinued),
    ],
    [html.text("Continue →")],
  )
}

fn int_to_string(n: Int) -> String {
  case n {
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    _ -> "?"
  }
}
