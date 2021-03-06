defmodule Mix.Tasks.Phoenix.New do
  use Mix.Task
  alias Phoenix.Naming

  @shortdoc "Creates Phoenix application"

  @template_priv_dir "template"

  @doc """
  Creates Phoenix application.
  """
  def run([name, path]) do
    application_name = Naming.underscore(name)
    application_module = Naming.camelize(application_name)
    project_path = make_project_path(path, application_name)

    bindings = [application_name: application_name,
                application_module: application_module,
                secret_key_base: random_string(64)]

    Mix.Generator.create_directory(project_path)

    for source_path <- template_files do
      destination_path = make_destination_path(project_path, source_path, application_name)

      if File.dir?(source_path) do
        Mix.Generator.create_directory(destination_path)
      else
        contents = eval_file(source_path, bindings)
        Mix.Generator.create_file(destination_path, contents)
      end
    end
  end

  @doc """
  Display instructions on how to create a Phoenix application.
  """
  def run(_) do
    Mix.shell.info """
    Supply application name and destination path.

    e.g.
      mix phoenix.new photo_blog /home/johndoe/
    """
  end

  defp eval_file(source_path, bindings) do
    if String.ends_with?(source_path, ".html.eex") do
      File.read!(source_path)
    else
      EEx.eval_file(source_path, bindings)
    end
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64
  end

  defp make_project_path(path, application_name) do
    basename = Naming.underscore(Path.basename(path))

    if basename == application_name do
      path
    else
      Path.join(path, application_name)
    end
  end

  defp template_files do
    file_pattern = Path.join(template_path, "**/*")

    Path.wildcard(file_pattern, match_dot: true)
  end

  defp make_destination_path(project_path, file, application_name) do
    new_path = String.replace(file, "application_name", application_name)
    relative_path = Path.relative_to(new_path, template_path)

    Path.join(project_path, relative_path)
  end

  def template_path do
    Path.join(Application.app_dir(:phoenix, "priv"), @template_priv_dir)
  end
end
