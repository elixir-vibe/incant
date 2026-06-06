# Visual regression captures

Incant keeps the default admin UI dense and restrained. Use the playground capture script for quick before/after visual review.

Start the playground:

```bash
cd examples/playground
PORT=4002 mix phx.server
```

From the repository root, capture the main flows:

```bash
OUT_DIR=tmp/visual-regression ./scripts/capture-playground-visuals.sh
```

The script visits and captures:

- dashboard: `/admin`
- product table: `/admin/resources/product`
- product detail: `/admin/resources/product/1`
- ticket new form: `/admin/resources/ticket/new`
- ticket edit form: `/admin/resources/ticket/99/edit`

Screenshots are local review artifacts and should not be committed by default.
