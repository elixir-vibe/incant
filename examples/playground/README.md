# Incant Playground

Phoenix playground for Incant development.

It uses the local `incant` path dependency and VibeKit conventions, then defines sample admin metadata for:

- product resource table
- LLM request resource table
- LLM proxy dashboard widgets
- Tailwind/CSS-variable theme contract

## Run

```sh
mix setup
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000).

## Checks

```sh
mix test
mix ci
```

The playground `mix ci` keeps VibeKit's Credo, ExDNA, and Reach checks. Dialyzer is intentionally omitted here because the generated Phoenix test support currently emits framework macro warnings that are not useful for playground iteration.
