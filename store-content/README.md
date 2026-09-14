# Store content

A theme carries templates and sections. It does not carry pages.

Uploading the theme ZIP to a new store gives that store the *layouts* for
policy, contact and tracking pages, but the pages themselves are store
content and have to exist before anything renders. That is why policy pages
look wrong — or 404 — on a store the theme was only uploaded to.

This folder is the content, kept here so it is written once rather than once
per store.

## Why it needs no editing per store

Every file is written with `[[tokens]]`. The theme substitutes them at render
time from that store's own settings, so the same HTML produces correct copy on
any store:

| In the file | Becomes |
| --- | --- |
| `[[store_name]]` | Settings → Store details → store name |
| `[[jurisdiction]]` | The store's state and country, for the governing-law clause |
| `[[handling_min]]`–`[[handling_max]]` | Theme settings → Shipping |
| `[[transit_min]]`–`[[transit_max]]` | Theme settings → Shipping |
| `[[delivery_min]]`–`[[delivery_max]]` | The two above, added together |
| `[[returns_days]]` | Theme settings → Returns |
| `[[timezone]]` | Theme settings → Store information |
| `[[refund_policy_url]]` and friends | Resolved to whichever exists on this store |

Paste the HTML as it is. Do not replace the tokens by hand — that is the whole
point of them, and doing it breaks the automatic updates.

## Setting up a new store

1. Upload the theme ZIP and publish it.
2. Fill in **Settings → Store details** — name, address, phone, support email.
   Everything on the storefront reads from here.
3. Create the pages in **Content → Pages**, one per row of `pages.json`:
   - Title and handle exactly as listed (the handle drives the footer links,
     and the theme detects legal pages from it).
   - Paste the matching file into the body in **HTML view**, not rich text.
     Rich text mangles the tables and escapes the tokens.
   - Set the theme template where the row names one. Pages with `"body": null`
     are rendered entirely by theme sections — leave those bodies empty.
4. Check the footer. If a policy link is missing, the page handle does not
   match.

Step 3 is the only per-store typing, and it is paste-only.

## If you skip step 3

The footer falls back to Shopify's own `/policies/*` URLs for any policy
filled in under **Settings → Policies**. Those pages work, but Shopify renders
them itself — they cannot use theme sections, so they have no store details
block and do not match the rest of the site. Pages are the reason the legal
pages look like the store.

If neither a page nor a Settings → Policies entry exists, the footer prints
"Policies are being updated." rather than a dead link.
