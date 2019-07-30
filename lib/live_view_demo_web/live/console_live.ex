defmodule LiveViewDemoWeb.ConsoleLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div>
      <form phx-submit="execute">
        <input type="text" name="command" value="<%= @command %>"/>
        <%= if @result do %><pre><%= @result %></pre><% end %>
      </form>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, command: "", result: nil)}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    {:noreply, assign(socket, command: command, result: command)}
  end
end
