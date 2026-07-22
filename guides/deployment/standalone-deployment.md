# Standalone Deployment

The standalone Incant release renders service-owned admin surfaces discovered over local [SafeRPC](https://hexdocs.pm/safe_rpc) sockets. It owns a Phoenix endpoint and registry, but no application database.

## Build the release

From the Incant source checkout:

```bash
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release incant
```

The release is written to:

```text
_build/prod/rel/incant
```

`assets.deploy` builds Incant's JavaScript, CSS, and Tailwind output before the Mix release copies `priv/static`.

## Build a ReleaseKit artifact

ReleaseKit can build assets, assemble the release, copy static files into it, and write an artifact manifest:

```bash
MIX_ENV=prod mix release_kit.artifact --out-dir _build/prod/artifacts
```

Output:

```text
_build/prod/artifacts/incant-<version>.tar.gz
_build/prod/artifacts/incant.etf
```

Use the standard Mix release when your deployment system does not consume ReleaseKit manifests.

## Runtime files

A typical host uses:

```text
/opt/incant/releases/<release>/       immutable unpacked release
/opt/incant/current/                  symlink to active release
/run/incant/rpc.etf                   trusted service binding file
/run/billing/admin.sock               service-owned SafeRPC socket
/run/llm-proxy/admin.sock             service-owned SafeRPC socket
```

Incant does not own the service sockets. Each service creates its socket and controls its permissions. The binding file points the Incant registry at those sockets.

## Runtime environment

```bash
INCANT_SERVE="true"
INCANT_HTTP_IP="127.0.0.1"
INCANT_HTTP_PORT="4000"
INCANT_SECRET_KEY_BASE="replace-with-at-least-64-random-bytes"
INCANT_LIVE_VIEW_SIGNING_SALT="replace-with-random-value"
HOSTKIT_RPC_BINDINGS="/run/incant/rpc.etf"
```

Optional indirection for the binding path variable:

```bash
INCANT_RPC_BINDINGS_ENV="MY_PLATFORM_RPC_BINDINGS"
MY_PLATFORM_RPC_BINDINGS="/run/incant/rpc.etf"
```

The secret key base and signing salt are service secrets. Do not commit them or place them in release manifests.

## Binding file

Generate bindings from trusted deployment data:

```elixir
bindings = %{
  "billing" => %{
    "socket" => "/run/billing/admin.sock",
    "modules" => ["Elixir.Billing.Admin"]
  },
  "llm_proxy" => %{
    "socket" => "/run/llm-proxy/admin.sock",
    "modules" => ["Elixir.LLMProxy.Admin"]
  }
}

File.write!("/run/incant/rpc.etf", :erlang.term_to_binary(bindings))
```

Write to a temporary file in the same runtime directory, set ownership/mode, then rename atomically. The Incant service account needs read access; untrusted users should not be able to replace the file or create referenced sockets.

## Start order

Recommended order:

1. Create runtime directories with final ownership and mode.
2. Start service-owned SafeRPC servers.
3. Write the binding ETF atomically.
4. Start Incant.
5. Verify registry discovery and rendered surfaces.

Standalone Incant allows an empty registry at boot, so strict ordering is not required. A service that appears later needs a registry refresh or Incant restart before it appears in the current snapshot.

## Start and verify

Start under a service supervisor, or manually:

```bash
/opt/incant/current/bin/incant start
```

Check health:

```bash
curl --fail --silent http://127.0.0.1:4000/health
```

Then verify:

1. The root admin lists intended services.
2. Resource indexes load from each service.
3. Detail views, filters, and pagination work.
4. An authorized non-destructive action succeeds.
5. An unauthorized actor/action is denied by the owning service.
6. Dark mode, dialogs, controls, and LiveView reconnects work through the reverse proxy.
7. The semantic API returns `application/vnd.incant.admin+json`.

## Reverse proxy and authentication

The endpoint binds loopback by default. Put it behind an authenticated operator boundary.

The reverse proxy must:

- terminate TLS for remote access;
- authenticate and authorize operators;
- proxy LiveView WebSockets at `/live/websocket`;
- preserve cookies and CSRF behavior;
- pass `/incant` API requests only from trusted operator clients;
- avoid exposing service Unix sockets or binding files.

Incant policies still run in each service. Reverse-proxy authentication does not replace service-level row and action authorization.

## Replacement and rollback

Incant stores registry state in memory and application data in owning services, so replacing the central host is straightforward:

1. Build and unpack a new immutable release.
2. Keep the same secret environment and binding file.
3. Stop the old endpoint.
4. Switch the active release symlink.
5. Start the new endpoint.
6. Verify health, registry discovery, LiveView, and API operations.

Rollback by switching to the previous release and repeating verification. A central Incant rollback does not roll back service contracts; keep service and Incant versions compatible when changing transport schemas.

## Backups

Standalone Incant has no primary application database. Back up:

- deployment source for binding generation;
- service configuration and socket ownership rules;
- secret-manager records for endpoint secrets;
- each owning service's data according to that service's recovery plan.

Do not back up live Unix socket files. Recreate runtime directories, binding files, and sockets during restore.
