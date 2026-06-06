# Live components

Incant is experimental; LiveView component organization may still change before a first stable release.

The generic renderer follows Phoenix-style module names. Root components expose `view/1` and nested resource modules keep local names concise:

```heex
<Shell.view context={@context}>
  <Dashboard.view context={@context} />
  <Resource.view context={@context} />
</Shell.view>
```

Resource rendering is split into header, form, detail, and table components.
