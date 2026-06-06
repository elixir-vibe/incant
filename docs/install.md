# Installation


Generate starter files in a Phoenix app:

```sh
mix incant.install
```

The task creates:

```text
lib/my_app/admin.ex
lib/my_app/admin/resources/sample.ex
lib/my_app/admin/themes/default.ex
```

The Igniter-powered installer also patches the Phoenix router and app CSS when it can detect them. If a file cannot be found or patched confidently, it prints fallback instructions.
