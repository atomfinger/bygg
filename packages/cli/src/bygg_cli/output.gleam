import bygg/generator.{type GeneratedProject}
import filepath
import gleam/list
import gleam/result
import simplifile
import snag

pub fn write_to_disk(
  project: GeneratedProject,
  outdir: String,
) -> snag.Result(Nil) {
  use _ <- result.try(
    simplifile.create_directory_all(outdir)
    |> result.map_error(fn(error) {
      snag.new(
        "Failed to create output directory: "
        <> simplifile.describe_error(error),
      )
    }),
  )

  list.try_each(project.files, fn(entry) {
    let full_path = filepath.join(outdir, entry.path)
    let dir = filepath.directory_name(full_path)
    use _ <- result.try(
      simplifile.create_directory_all(dir)
      |> result.map_error(fn(error) {
        snag.new(
          "Failed to create directory "
          <> dir
          <> ": "
          <> simplifile.describe_error(error),
        )
      }),
    )
    simplifile.write(full_path, entry.content)
    |> result.map_error(fn(error) {
      snag.new(
        "Failed to write "
        <> full_path
        <> ": "
        <> simplifile.describe_error(error),
      )
    })
  })
}
