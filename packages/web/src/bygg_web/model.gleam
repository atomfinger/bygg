import bygg/catalog.{type Category}
import bygg/config.{type Target, Erlang}
import gleam/option.{type Option, None}
import gleam/set.{type Set}

pub type Tab {
  LandingTab
  DepsTab
  ArchetypeTab
  WizardTab
}

pub type WizardStep {
  AskPurpose
  AskDatabase
  AskMessaging
  AskTesting
  AskCi
  WizardDone
}

pub type Model {
  Model(
    project_name: String,
    target: Target,
    active_tab: Tab,
    selected_deps: Set(String),
    selected_archetype: Option(String),
    active_category: Option(Category),
    wizard_step: WizardStep,
    purpose: Option(String),
    db_choice: Option(String),
    msg_choice: Option(String),
    test_choices: Set(String),
    ci_choice: Option(String),
    generate_error: Option(String),
    last_generated: Option(String),
  )
}

pub type Msg {
  UserSetProjectName(String)
  UserSetTarget(Target)
  UserSwitchedTab(Tab)
  UserFilteredCategory(Option(Category))
  UserToggledDep(String)
  UserSelectedArchetype(String)
  UserClickedGenerate
  GenerateFailed(String)
  GenerateSucceeded(String)
  UserStartedOver
  WizardAnsweredPurpose(String)
  WizardChoseDatabase(Option(String))
  WizardChoseMessaging(Option(String))
  WizardToggledTestTool(String)
  WizardChoseCi(Option(String))
  WizardContinued
  WizardBack
  WizardApply
}

pub fn init(_flags: Nil) -> Model {
  Model(
    project_name: "my_app",
    target: Erlang,
    active_tab: LandingTab,
    selected_deps: set.new(),
    selected_archetype: None,
    active_category: None,
    wizard_step: AskPurpose,
    purpose: None,
    db_choice: None,
    msg_choice: None,
    test_choices: set.new(),
    ci_choice: None,
    generate_error: None,
    last_generated: None,
  )
}
