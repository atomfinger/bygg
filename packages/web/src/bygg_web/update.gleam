import bygg/archetype
import bygg/catalog
import bygg/config.{type SelectedPackage, SelectedPackage}
import bygg/generator
import bygg_web/effect as app_effect
import bygg_web/model.{
  type Model, type Msg, AskCi, AskDatabase, AskMessaging, AskPurpose, AskTesting,
  DepsTab, GenerateFailed, GenerateSucceeded, Model, UserClickedGenerate,
  UserFilteredCategory, UserSelectedArchetype, UserSetProjectName, UserSetTarget,
  UserStartedOver, UserSwitchedTab, UserToggledDep, WizardAnsweredPurpose,
  WizardApply, WizardBack, WizardChoseCi, WizardChoseDatabase,
  WizardChoseMessaging, WizardContinued, WizardDone, WizardToggledTestTool,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSetProjectName(name) -> #(
      Model(..model, project_name: name, generate_error: None),
      effect.none(),
    )

    UserSetTarget(target) -> {
      let compatible_deps =
        model.selected_deps
        |> set.to_list
        |> list.filter(fn(name) {
          case catalog.find_by_name(name) {
            Ok(pkg) ->
              case pkg.targets, target {
                catalog.ErlangOnly, config.Erlang -> True
                catalog.JavaScriptOnly, config.JavaScript -> True
                catalog.BothTargets, _ -> True
                _, _ -> False
              }
            Error(_) -> True
          }
        })
        |> set.from_list
      #(
        Model(
          ..model,
          target: target,
          selected_deps: compatible_deps,
          generate_error: None,
        ),
        effect.none(),
      )
    }

    UserSwitchedTab(tab) -> #(
      Model(
        ..model,
        active_tab: tab,
        generate_error: None,
        last_generated: None,
      ),
      effect.none(),
    )

    UserFilteredCategory(cat) -> #(
      Model(..model, active_category: cat),
      effect.none(),
    )

    UserToggledDep(name) -> {
      let deps = case set.contains(model.selected_deps, name) {
        True -> set.delete(model.selected_deps, name)
        False -> set.insert(model.selected_deps, name)
      }
      #(
        Model(
          ..model,
          selected_deps: deps,
          selected_archetype: None,
          generate_error: None,
        ),
        effect.none(),
      )
    }

    UserSelectedArchetype(name) -> {
      let target = case archetype.find(name) {
        Ok(arch) -> arch.target
        Error(_) -> model.target
      }
      #(
        Model(
          ..model,
          selected_archetype: Some(name),
          selected_deps: set.new(),
          target: target,
          generate_error: None,
        ),
        effect.none(),
      )
    }

    UserClickedGenerate -> generate(model)

    GenerateFailed(err) -> #(
      Model(..model, generate_error: Some(err)),
      effect.none(),
    )

    GenerateSucceeded(name) -> #(
      Model(..model, last_generated: Some(name), generate_error: None),
      effect.none(),
    )

    UserStartedOver -> #(model.init(Nil), effect.none())

    WizardAnsweredPurpose(purpose) -> {
      let next_step = case purpose {
        "rest-api" | "ssr-website" -> AskDatabase
        _ -> AskCi
      }
      #(
        Model(
          ..model,
          purpose: Some(purpose),
          db_choice: None,
          msg_choice: None,
          test_choices: set.new(),
          wizard_step: next_step,
        ),
        effect.none(),
      )
    }

    WizardChoseDatabase(choice) -> #(
      Model(..model, db_choice: choice, wizard_step: AskMessaging),
      effect.none(),
    )

    WizardChoseMessaging(choice) -> #(
      Model(..model, msg_choice: choice, wizard_step: AskTesting),
      effect.none(),
    )

    WizardToggledTestTool(name) -> {
      let choices = case set.contains(model.test_choices, name) {
        True -> set.delete(model.test_choices, name)
        False -> set.insert(model.test_choices, name)
      }
      #(Model(..model, test_choices: choices), effect.none())
    }

    WizardChoseCi(choice) -> #(
      Model(..model, ci_choice: choice, wizard_step: WizardDone),
      effect.none(),
    )

    WizardContinued -> #(Model(..model, wizard_step: AskCi), effect.none())

    WizardBack -> {
      let prev = case model.wizard_step {
        AskDatabase -> AskPurpose
        AskMessaging -> AskDatabase
        AskTesting ->
          case model.purpose {
            Some("rest-api") | Some("ssr-website") -> AskMessaging
            _ -> AskPurpose
          }
        AskCi ->
          case model.purpose {
            Some("rest-api") | Some("ssr-website") -> AskTesting
            _ -> AskPurpose
          }
        WizardDone -> AskCi
        AskPurpose -> AskPurpose
      }
      #(Model(..model, wizard_step: prev), effect.none())
    }

    WizardApply -> {
      let applied = apply_wizard_state(model)
      generate(applied)
    }
  }
}

fn generate(model: Model) -> #(Model, Effect(Msg)) {
  let cfg = case model.selected_archetype {
    Some(name) ->
      config.ProjectConfig(
        ..config.default(model.project_name),
        archetype: Some(name),
      )

    None -> {
      let deps = resolve_deps(set.to_list(model.selected_deps))
      config.ProjectConfig(
        ..config.default(model.project_name),
        target: model.target,
        dependencies: deps,
      )
    }
  }

  case generator.generate(cfg) {
    Error(err) -> #(Model(..model, generate_error: Some(err)), effect.none())
    Ok(project) -> #(
      Model(
        ..model,
        generate_error: None,
        last_generated: Some(model.project_name),
      ),
      app_effect.download_zip(model.project_name, project.files),
    )
  }
}

fn apply_wizard_state(model: Model) -> Model {
  let purpose = option.unwrap(model.purpose, "")
  let arch_name = case purpose {
    "rest-api" -> Some("rest-api")
    "ssr-website" -> Some("ssr-website")
    "browser-app" -> Some("browser-app")
    _ -> None
  }

  let #(arch_deps, target) = case arch_name {
    Some(name) ->
      case archetype.find(name) {
        Ok(arch) -> #(set.from_list(arch.dependencies), arch.target)
        Error(_) -> #(set.new(), model.target)
      }
    None -> #(set.new(), model.target)
  }

  let extra_deps =
    [model.db_choice, model.msg_choice, model.ci_choice]
    |> list.filter_map(fn(opt) { option.to_result(opt, Nil) })
    |> set.from_list
    |> set.union(model.test_choices)
    |> set.union(arch_deps)

  Model(
    ..model,
    selected_archetype: None,
    selected_deps: extra_deps,
    target: target,
    active_tab: DepsTab,
    wizard_step: AskPurpose,
    purpose: None,
    db_choice: None,
    msg_choice: None,
    test_choices: set.new(),
    ci_choice: None,
  )
}

fn resolve_deps(names: List(String)) -> List(SelectedPackage) {
  list.filter_map(names, fn(name) {
    case catalog.find_by_name(name) {
      Ok(pkg) ->
        Ok(SelectedPackage(
          name: pkg.name,
          hex_name: option.unwrap(pkg.hex_name, pkg.name),
          version_constraint: option.unwrap(
            pkg.default_constraint,
            ">= 1.0.0 and < 2.0.0",
          ),
        ))
      Error(_) -> Error(Nil)
    }
  })
}
