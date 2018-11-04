defmodule EWallet.Seeder.CLI do
  @moduledoc """
  Provides an interactive seeder.
  """

  defmodule Writer do
    @moduledoc """
    Provides an interactive writer.
    """

    alias EWallet.CLI

    def success(message), do: CLI.success(message)
    def warn(message), do: CLI.warn(message)
    def error(message), do: CLI.error("  #{message}")

    def heading(message), do: CLI.heading(message)
    def print(message), do: CLI.print(message)

    def print_errors(%{errors: errors}) do
      Enum.each(errors, fn {field, {message, _}} ->
        error("  `#{field}` #{message}")
      end)
    end
  end

  alias EWallet.CLI
  alias EWallet.EmailValidator
  alias EWallet.Seeder
  alias EWalletDB.Validator

  @confirm_message """
  Please verify that the information you've entered are correct.
  Press Enter to start seeding or `Ctrl+C` twice to exit.
  """

  def run(srcs, assume_yes) do
    mods = Seeder.gather_seeds(srcs)
    reporters = Seeder.gather_reporters(srcs)

    args =
      mods
      |> Seeder.argsline_for()
      |> process_argsline(assume_yes)

    _ =
      unless assume_yes do
        _ = IO.puts("\n-----\n")
        _ = IO.gets(@confirm_message)
      end

    args = run_seeds(mods, args)
    run_reporters(reporters, args)
  end

  defp run_seeds([], args), do: args

  defp run_seeds([mod | t], args) do
    case Keyword.get(mod.seed, :run_banner) do
      nil -> nil
      t -> CLI.print(t)
    end

    case mod.run(Writer, args) do
      n when is_list(n) -> run_seeds(t, n)
      _ -> run_seeds(t, args)
    end
  end

  defp run_reporters([], args), do: args

  defp run_reporters([reporter | t], args) do
    reporter.run(Writer, args)
    run_reporters(t, args)
  end

  #
  # Argsline processing
  #

  defp process_argsline(argsline, assume_yes), do: process_argsline(argsline, [], assume_yes)
  defp process_argsline([], acc, _), do: acc

  defp process_argsline([{:title, _title} | t], acc, true) do
    process_argsline(t, acc, true)
  end

  defp process_argsline([{:title, title} | t], acc, assume_yes) do
    CLI.print(".")
    CLI.print("## #{title}\n")
    process_argsline(t, acc, assume_yes)
  end

  defp process_argsline([{:text, _text} | t], acc, true) do
    process_argsline(t, acc, true)
  end

  defp process_argsline([{:text, text} | t], acc, assume_yes) do
    CLI.print(text)
    process_argsline(t, acc, assume_yes)
  end

  defp process_argsline([{:input, {_, name, _prompt, default}} | t], acc, true) do
    process_argsline(t, acc ++ [{name, process_default(default)}], true)
  end

  defp process_argsline([{:input, input} | t], acc, false) do
    case process_input(input) do
      nil -> process_argsline(t, acc, false)
      {_, _} = a -> process_argsline(t, acc ++ [a], false)
    end
  end

  defp process_argsline([_ | t], acc, assume_yes) do
    process_argsline(t, acc, assume_yes)
  end

  #
  # Input processing
  #

  defp process_input({type, name, prompt}), do: process_input({type, name, prompt, nil})

  defp process_input({:text, name, prompt, default} = input) do
    prompt_text = prompt_for(prompt, default)

    val =
      prompt_text
      |> IO.gets()
      |> String.trim()

    cond do
      byte_size(val) == 0 ->
        {name, process_default(default)}

      length(val) > 0 ->
        {name, val}

      true ->
        IO.puts("#{prompt} is invalid. Please try again.")
        process_input(input)
    end
  end

  defp process_input({:email, name, prompt, default} = input) do
    prompt_text = prompt_for(prompt, default)

    val =
      prompt_text
      |> IO.gets()
      |> String.trim()

    cond do
      byte_size(val) == 0 ->
        {name, process_default(default)}

      EmailValidator.valid?(val) ->
        {name, val}

      true ->
        IO.puts("#{prompt} is invalid. Please try again.")
        process_input(input)
    end
  end

  defp process_input({:password, name, prompt, default} = input) do
    prompt_text = prompt_for(prompt, default)

    val =
      prompt_text
      |> CLI.gets_sensitive()
      |> String.trim()

    if byte_size(val) == 0 do
      {name, process_default(default)}
    else
      case Validator.validate_password(val) do
        {:ok, password} ->
          {name, password}

        {:error, :password_too_short, d} ->
          IO.puts("#{prompt} must be at least #{d[:min_length]} characters. Please try again.")
          process_input(input)
      end
    end
  end

  defp process_input(_) do
    nil
  end

  #
  # Utils
  #

  defp prompt_for(l, nil), do: "#{l}: "
  defp prompt_for(l, d) when is_binary(d), do: "#{l} (#{d}): "
  defp prompt_for(l, {_, _, _}), do: "#{l} (auto-generated): "
  defp prompt_for(l, _), do: prompt_for(l, nil)

  defp process_default({mod, func, args}), do: apply(mod, func, args)
  defp process_default(default), do: default
end
