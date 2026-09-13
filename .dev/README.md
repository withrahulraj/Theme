# Dev checks

Local validation for the theme. None of this ships to a store — `.shopifyignore`
keeps it out of `shopify theme push`.

```bash
# Liquid syntax, schema and Shopify best practices (needs npm)
npm install @shopify/theme-check-node
node .dev/check.mjs

# Renders the new snippets and sections against stubbed Shopify data (needs
# the `liquid` gem: gem install liquid)
ruby .dev/render_test.rb
ruby .dev/section_test.rb

# Cross-checks every template JSON against the section schemas, and every
# settings.* reference against settings_schema.json
python3 .dev/validate_templates.py
```

`render_test.rb` and `section_test.rb` stub the Shopify-specific filters
(`payment_type_svg_tag`, `image_tag`, `inline_asset_content`, …) and drops
(`shop`, `settings`, `routes`, `collections`, `pages`). They model Shopify's
`{% render %}` scoping, where the global drops stay visible inside a snippet but
the caller's own assigns do not.

The checks cover a fully configured store and a brand new one with no address,
no phone, no policies and no pages — the case that matters when the theme is
installed on a fresh store.
