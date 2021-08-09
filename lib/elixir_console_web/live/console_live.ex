defmodule ElixirConsoleWeb.ConsoleLive do
  @moduledoc """
  This is the live view component that implements the console UI.
  """

  use Phoenix.LiveView

  alias ElixirConsole.Sandbox
  alias ElixirConsoleWeb.LiveMonitor

  defmodule Output do
    @enforce_keys [:command, :id]
    defstruct [:command, :result, :error, :id]
  end

  def mount(_params, _session, socket) do
    sandbox = Sandbox.init()
    LiveMonitor.monitor(self(), __MODULE__, %{id: socket.id, sandbox: sandbox})

    {:ok,
     assign(
       socket,
       output: [],
       history: [],
       suggestions: [],
       contextual_help: nil,
       command_id: 0,
       sandbox: sandbox
     )}
  end

  @doc "Function invoked when the live view process is finished. See LiveMonitor.terminate/1."
  def unmount(%{sandbox: sandbox}) do
    Sandbox.terminate(sandbox)
  end

  def print_prompt, do: "> "

  # This event comes from HistoryComponent
  def handle_info({:show_function_docs, contextual_help}, socket) do
    {:noreply,
     socket
     |> assign(contextual_help: contextual_help)
     |> assign(suggestions: [])}
  end

  # This event comes from CommandInputComponent
  def handle_info({:update_suggestions, suggestions}, socket) do
    {:noreply, assign(socket, suggestions: suggestions)}
  end

  # This event comes from CommandInputComponent
  def handle_info({:execute_command, command}, socket) do
    history =
      if socket.assigns.history == [] do
        [command]
      else
        [command | socket.assigns.history]
      end

    case execute_command(command, socket.assigns.sandbox) do
      {:ok, result, sandbox} ->
        {:noreply,
         socket
         |> append_output(:ok, command, result)
         |> assign(sandbox: sandbox)
         |> assign(history: history)
         |> assign(suggestions: [])
         |> assign(input_value: "")
         |> assign(contextual_help: nil)}

      {:error, error, sandbox} ->
        LiveMonitor.update_sandbox(self(), __MODULE__, %{id: socket.id, sandbox: sandbox})

        {:noreply,
         socket
         |> append_output(:error, command, error)
         |> assign(sandbox: sandbox)
         |> assign(history: history)
         |> assign(suggestions: [])
         |> assign(input_value: "")
         |> assign(contextual_help: nil)}
    end
  end

  defp execute_command(command, sandbox) do
    case Sandbox.execute(command, sandbox) do
      {:success, {result, sandbox}} ->
        {:ok, inspect(result), sandbox}

      {:error, {error_string, sandbox}} ->
        {:error, error_string, sandbox}
    end
  end

  defp append_output(socket, status, command, result_or_error) do
    socket
    |> assign(output: [build_output(status, command, result_or_error, socket.assigns.command_id)])
    |> assign(command_id: socket.assigns.command_id + 1)
  end

  defp build_output(:ok, command, result, id),
    do: %Output{command: command, result: result, id: id}

  defp build_output(:error, command, error, id),
    do: %Output{command: command, error: error, id: id}
end
