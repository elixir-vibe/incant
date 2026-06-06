# Release checklist

Incant is still experimental. Use this checklist before publishing a Hex release.

## Package metadata

- Confirm package name and ownership on Hex.pm.
- Add package description, licenses, links, and maintainers in `mix.exs`.
- Confirm dependency constraints are appropriate for library consumers.
- Keep installer dependencies intentional; Igniter is runtime `false` but available to the install task.

## Versioning

- Set `version` in `mix.exs`.
- Add or update a changelog before tagging.
- Avoid breaking DSL/API changes without a version bump.

## Docs

- Keep `README.md` focused on quick start and links.
- Keep detailed guides under `docs/`.
- Verify examples compile or are clearly marked conceptual.
- Update `PLAN.md`, `CONVENTIONS.md`, and `REFERENCES.md` when product direction changes.

## Current status

Latest local release-prep smoke:

- `mix ci` passes.
- `cd examples/playground && mix test` passes.
- Playground `/admin` renders in a local Phoenix server.
- API naming remains `actor`, `actor_assign`, `actor`, and `policy` for now.

## Tests

Run:

```sh
mix test
cd examples/playground && mix test
```

Before release, also run the full project CI alias when dependencies/tools are available:

```sh
mix ci
```

## Playground

- Confirm `/admin` renders.
- Confirm Catalog, LLM, and Support examples still make sense.
- Avoid public demo routes that look like product API unless documented.

## Installer

- Test `mix incant.install` in a fresh Phoenix app.
- Verify starter files are generated.
- Verify router patch is correct.
- Verify Tailwind CSS source patch is correct.
- Verify fallback instructions are useful when files are missing.

## Authorization

- Confirm default behavior remains allow-all without a policy.
- Confirm `actor_assign` and `actor` callback extraction work.
- Confirm policy scoping protects list and detail data.
- Confirm local resource/dashboard policies override the admin policy where intended.

## Publishing

```sh
mix hex.build
mix hex.publish
```

Tag the release after publishing:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```
