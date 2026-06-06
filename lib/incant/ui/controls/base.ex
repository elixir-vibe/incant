defmodule Incant.UI.Controls.Base do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      defstruct [
        :id,
        :name,
        :label,
        :role,
        :value,
        :default,
        :placeholder,
        :disabled,
        :readonly,
        :required,
        :commit,
        :source,
        :options,
        :clearable,
        :input_format,
        :presets,
        :cardinality,
        :display,
        :search_event,
        :min_query_length,
        errors: [],
        events: %{},
        behavior: %{}
      ]
    end
  end
end
