import bygg/catalog
import bygg/config.{type ProjectConfig, JavaScript}
import gleam/list

pub type ApplicationProfile {
  BasicApp
  WebServer
  BrowserApp
  LustreComponent
  LustreServerComponent
  Library
}

pub fn detect(config: ProjectConfig) -> ApplicationProfile {
  let dep_names: List(String) =
    list.map(config.dependencies, fn(dependency) { dependency.name })

  let has_server =
    catalog.has_role(dep_names, catalog.WebFramework)
    || catalog.has_role(dep_names, catalog.HttpServer)

  let has_spa = catalog.has_role(dep_names, catalog.FrontendFramework)
  let has_component = catalog.has_role(dep_names, catalog.LustreComponent)
  let has_server_component =
    catalog.has_role(dep_names, catalog.LustreServerComponent)

  case
    has_server_component,
    has_component,
    has_spa && config.target == JavaScript,
    has_server
  {
    True, _, _, _ -> LustreServerComponent
    _, True, _, _ -> LustreComponent
    _, _, True, _ -> BrowserApp
    _, _, _, True -> WebServer
    _, _, _, _ -> BasicApp
  }
}

pub fn label(profile: ApplicationProfile) -> String {
  case profile {
    BasicApp -> "Basic Application"
    WebServer -> "Web Server"
    BrowserApp -> "Browser Application"
    LustreComponent -> "Lustre Web Component"
    LustreServerComponent -> "Lustre Server Component"
    Library -> "Library"
  }
}
