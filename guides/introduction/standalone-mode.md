# Standalone Mode

Standalone mode runs Incant as a central LiveView admin and semantic HTTP API. It discovers service-owned admin contracts over [SafeRPC](https://hexdocs.pm/safe_rpc) and renders them without loading service schemas, repos, queries, or action callbacks into the central VM.

Use this mode when several independently deployed services should appear in one operator interface.

## Service-owned admin modules

Each service declares its own surfaces:

```elixir
defmodule Billing.Admin do
  use Incant.Admin,
    service: :billing,
    version: "1",
    repo: Billing.Repo,
    policy: Billing.Admin.Policy,
    rpc: true

  expose Billing.Invoices.Invoice
  expose Billing.Customers.Customer
  dashboard Billing.Admin.Dashboards.Operations
end
```

`rpc: true` exposes the standard Incant service operations through SafeRPC:

```text
{Billing.Admin, :describe}
{Billing.Admin, :index}
{Billing.Admin, :read}
{Billing.Admin, :run_action}
```

The service still owns execution. `describe` returns portable metadata; index, read, and action calls execute against the service's repo and policy inside the service VM.

## Serve the service contract

A service hosts its admin module on a local SafeRPC socket:

```elixir
defmodule Billing.AdminServer do
  use SafeRPC.Adapter.Server, service: Billing.Admin
end
```

Add the server to the service supervision tree with a protected Unix socket path:

```elixir
children = [
  {Billing.AdminServer, socket: "/run/billing/admin.sock"}
]
```

Use a root-owned runtime directory and group permissions so only the service and central Incant host can access the socket.

## Registry bindings

The central host reads an ETF file containing local SafeRPC bindings. A decoded binding has this shape:

```elixir
%{
  "billing" => %{
    "socket" => "/run/billing/admin.sock",
    "modules" => ["Elixir.Billing.Admin"]
  }
}
```

Generate the ETF file from trusted deployment configuration rather than accepting it over the network:

```elixir
File.write!(path, :erlang.term_to_binary(bindings))
```

`Incant.Service.Registry` decodes it with `:erlang.binary_to_term(binary, [:safe])`, validates bounded binding keys and module names, connects to each socket, reads SafeRPC descriptors, and asks Incant service modules for their contracts.

The default environment variable points to the file:

```text
HOSTKIT_RPC_BINDINGS=/run/incant/rpc.etf
```

Use `INCANT_RPC_BINDINGS_ENV` when the binding-path variable has another name.

## Start standalone Incant

Production runtime variables:

```text
INCANT_SERVE=true
INCANT_HTTP_IP=127.0.0.1
INCANT_HTTP_PORT=4000
INCANT_SECRET_KEY_BASE=replace-with-at-least-64-random-bytes
INCANT_LIVE_VIEW_SIGNING_SALT=replace-with-random-value
HOSTKIT_RPC_BINDINGS=/run/incant/rpc.etf
```

`INCANT_SERVE=true` starts:

- `Incant.PubSub`;
- `Incant.Service.RegistryServer`;
- `Incant.Web.Endpoint`.

The registry allows an empty binding set at startup, so the admin can boot before every service is available. Refreshing the registry discovers current contracts.

## Interfaces

The standalone endpoint serves:

- a LiveView admin rooted at `/`;
- a semantic JSON API rooted at `/incant`;
- compiled Incant assets;
- `/health` for service checks.

The JSON API exposes Incant session operations only. It does not permit arbitrary remote module/function calls.

## Security boundary

The bundled endpoint does not create an operator identity system. Keep the loopback bind and place the service behind an authenticated reverse proxy or private operator gateway.

A secure deployment should:

- authenticate operators before forwarding `/admin` or `/incant`;
- restrict the HTTP listener to loopback or a private interface;
- protect binding files and Unix sockets with ownership and mode;
- keep service policies enabled even when the central proxy authenticates users;
- avoid treating actor/context maps from untrusted callers as proof of identity;
- use TLS at the reverse proxy or ingress boundary.

Central authentication and service authorization are separate layers. The service remains responsible for deciding whether a described or requested operation is allowed.

## Library mode stays isolated

When `serve?: false` (the default), Incant starts no PubSub, registry, endpoint, or listener. A Phoenix application mounting local Incant surfaces remains ordinary [Library Mode](library-mode.md).

## Continue reading

- [Distributed Services](../features/distributed-services.md)
- [Standalone Deployment](../deployment/standalone-deployment.md)
- [Admin HTTP API](../reference/admin-http-api.cheatmd)
- [Architecture](../internals/architecture.md)
