# Live components

Incant is experimental; internal LiveView component modules may still change before a first stable release.


The generic renderer follows Phoenix-style module names. Root components expose `view/1` and nested resource modules keep local names concise:

```heex
<Shell.view context={@context}>
  <Dashboard.view context={@context} />
  <Resource.view context={@context} />
</Shell.view>
```

Resource rendering is split across `Incant.Live.Resource.Header`, `Incant.Live.Resource.Form`, `Incant.Live.Resource.Detail`, and `Incant.Live.Resource.Table`.
