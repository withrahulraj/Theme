# Universal lighting theme — setup

Shopify's official **Dawn 16.0.0**, with a store-driven header, footer, homepage,
support pages and product page layered on top. Nothing here is hardcoded to one
shop: the same theme ZIP can be uploaded to any number of lighting stores and it
fills itself in from that store's own settings.

## Typography

Inter throughout — headings at weight 500 (`inter_n5`), body at 400
(`inter_n4`), zero letter-spacing, and a 12px root that puts body copy at 18px.
Change it in Theme settings → Typography like any Dawn theme.

## Install on a new store

1. Download this repository as a ZIP (or run `shopify theme push`).
2. Online Store → Themes → Add theme → Upload ZIP file.
3. Customize → and you are done. Every section already has content.

## What fills itself in

| Surface | Comes from |
|---|---|
| Footer column 1 (name, address, phone, email) | Settings → Store details |
| Footer working days and hours | Theme settings → Store information |
| Footer column 2 (policies) | Settings → Policies — each published policy is linked automatically |
| Footer column 3 (help center) | The store's real Contact / About / Track order / FAQ pages, found by handle |
| Header and drawer menu | Theme settings → Navigation (auto menu) — the Shop dropdown lists the store's collections |
| Contact page cards | Settings → Store details |
| Product "Ships by" date | Today + the handling time in Theme settings → Shipping, returns & trust |
| Product rating | The `reviews.rating` metafields written by review apps, with a theme-settings fallback |
| Product stock line | The selected variant's real inventory |
| Payment icons | Theme settings → Shipping, returns & trust — drawn whether or not a provider is active yet |

Change a store detail once in Shopify admin and the footer, contact page and
tracking page all follow. There is nothing to re-enter per store.

## The three things worth checking per store

1. **Settings → Store details** — name, address, phone and support email.
2. **Settings → Policies** — publish the policies you want in the footer.
3. **Theme settings → Shipping, returns & trust** — handling time, returns
   window, and the tracking lookup URL (see below).

## Pages to create

**A theme carries templates and sections; it does not carry pages.** Uploading
the ZIP to a new store gives it the layouts, but the pages themselves are store
content and have to be created there. This is the one step that is genuinely
per-store, and it is the usual reason policy pages look wrong on a store the
theme was only uploaded to.

**The five legal documents need no content.** They are built into the theme, so
creating the page and leaving the body empty is enough — the document appears,
with that store's own name, delivery windows and contact details filled in.

To change one on a single store, type into the page body; that replaces the
built-in document, and clearing the body brings it back. To change one across
every store, edit `snippets/policy-body-*.liquid` and re-upload the theme.

Only About Us needs pasting, and it is in `store-content/`. See
`store-content/README.md`.

Shopify does not assign templates by handle, so pick the template in the page
editor's **Theme template** dropdown. The one exception is the store details
block on legal pages, which the stock `page` template adds by itself — so a
policy page still carries trading details if you forget.

The menu and footer start linking to a page the moment it exists.

| Page handle | Template | What it renders |
|---|---|---|
| `contact` | `page.contact` | Contact cards + contact form + trust strip |
| `track-order` | `page.track-order` | Tracking form + timeline + contact cards |
| `privacy-policy`, `refund-policy`, `shipping-policy`, `terms-of-service`, `payment-policy` | `page.policy` | Narrow legal layout with a last-updated line and a help box |
| `about-us` | `page` (default) | Your content + trust strip + newsletter |
| an empty `privacy-policy` etc. | either | The theme's built-in document for that handle |
| anything else | `page` (default) | Your content + trust strip + newsletter |

Alternative handles are recognised too, so an existing store does not need its
pages renamed: `contact-us`, `track-your-order`, `order-tracking`, `tracking`,
`about`, `our-story`, `faq`, `payment-policy`.

Until a page exists, the footer falls back to whatever is published under
Settings → Policies. Those URLs work, but Shopify renders `/policies/*` itself
and they cannot use theme sections — no store details block, and a layout that
does not match the rest of the site. That is why the legal documents are
published as pages.

## Two things the theme fills in for you

**Image alt text.** Empty alt text is the most common accessibility failure in a
Shopify catalogue, and it costs image-search traffic. Where a merchant has not
written alt text, the theme builds it from the product or collection title —
adding the variant name and a gallery position where they apply. Alt text you
*have* written always wins.

**SKUs in structured data.** Where a variant has no SKU, the theme generates a
stable one from your store name (`brightloft` → `BRI-317421-331468`) so every
offer in the Google markup carries an identifier. It is derived from IDs, not a
counter, so the same variant produces the same code on every render.

> This fills a gap in the storefront markup only. **It does not write SKUs into
> your product records** — no theme can do that, and your Shopify admin and
> product feed will still show the SKU field as empty. To have matching codes
> everywhere, write them to the variants via an app, a CSV import, or the API.

Both are on by default and can be turned off in Theme settings → Product page.

## Trading details on every policy page

Every policy page ends with a labelled block of the store's details — name,
address, phone, email, and working days with hours and timezone. It reads
straight from Settings → Store details, so the pages carry correct trading
details without anyone retyping them, and one change in admin updates them all.

Rows with nothing behind them are skipped rather than printed empty, so a store
with no phone number does not get a blank "Phone" row.

The timezone comes from your Shopify store timezone by default (shown as EST,
PST and so on), so opening hours are never ambiguous. Set one explicitly in
Theme settings → Store information if you want to override it.

This happens two ways, so it survives a store where nobody assigned templates:

- Pages on the **policy** template render through the Legal document section,
  which always carries the block.
- The **stock page template** adds it too, on any page whose handle reads as a
  legal document — `privacy-policy`, `refund-policy`, `shipping-policy`,
  `terms-of-service`, `payment-policy`, `cookie-policy` and so on. Nothing to
  assign; a page created today gets it.

Ordinary pages — About, Contact, Track Order, FAQ — are left alone. Change that
in Page → Store details, which offers *On legal pages only* (the default), *On
every page* or *Never*. Turn it off on the policy template in the Legal document
section instead. To put the same block anywhere by hand, write
`[[store_details]]` in the page body.

### Do not put an empty `"default": ""` in a section schema

Shopify's theme importer validates every section schema and **silently drops**
any section that fails — and then drops every template referencing it, with no
error anywhere. An empty string as the `default` of a `text` setting is one such
failure. Omit the key instead of defaulting it to `""`.

This cost four build-and-import cycles to find, so `.dev/validate_templates.py`
now fails the build on it. Run it before packaging a ZIP.

## Write policy copy once, not per store

Policy pages, and the shipping / returns / payments tabs on the product page,
are all written with tokens. Change a setting and every one of them follows —
there is no per-store copy to rewrite when handling time or the returns window
differs.

The product page tabs ship with token copy out of the box, so on a new store
they already state that store's real shipping window and returns period rather
than numbers typed for somebody else's shop.

Contact details appear once per policy page, in the store details block. The
separate help box is off by default because it repeats them; turn it on in the
Policy content section if you want it.

## Page tokens — write it once, keep it current

Legal pages usually go stale because the support email or returns window is
typed into the text. Write a token instead and the page follows your settings.

Type `[[email]]` in any page body and the live address renders. Tokens work on
every page and on the policy template.

| Token | Comes from |
|---|---|
| `[[store_name]]` | Store name (or the theme override) |
| `[[email]]` / `[[email_link]]` | Support email — plain, or as a `mailto:` link |
| `[[phone]]` / `[[phone_link]]` | Phone — plain, or as a `tel:` link |
| `[[address]]` | Store address, on one line |
| `[[hours_days]]` / `[[hours_time]]` | Working days, and hours with the timezone already appended |
| `[[timezone]]` | Timezone on its own |
| `[[store_details]]` | The whole labelled details block |
| `[[support_note]]` | Support note |
| `[[returns_days]]` | Returns window |
| `[[handling_min]]` / `[[handling_max]]` | Handling time |
| `[[transit_min]]` / `[[transit_max]]` | Transit time |
| `[[delivery_min]]` / `[[delivery_max]]` | Handling + transit, added up for you |
| `[[shipping_countries]]` | Countries you ship to |
| `[[free_shipping_label]]` | Free shipping label |
| `[[contact_url]]` / `[[track_url]]` / `[[about_url]]` | Those pages, resolved by handle |
| `[[refund_policy_url]]` / `[[shipping_policy_url]]` / `[[privacy_policy_url]]` / `[[terms_url]]` | Policy links, policy first then page |
| `[[year]]` | Current year |

A token with no value behind it renders empty rather than breaking the page, so
check the result if you leave a store setting blank.

Only this fixed list is substituted. Liquid written into a page body is **not**
executed — `{{ shop.email }}` in a page stays literal text.

## Policies

Shopify renders `/policies/*` URLs itself and they **cannot be themed** — there
is no `policy` template type. So the theme covers policies two ways:

1. **Pages** — a page whose handle is `refund-policy`, `shipping-policy`,
   `terms-of-service`, `privacy-policy` or `payment-policy`, on the **policy**
   template. The footer links these first, because they are the ones that can
   carry the theme's layout and store details block.
2. **Settings → Policies** — used when no matching page exists. Publish these
   as well regardless: they are what checkout links, and what Merchant Center
   and Shopify's compliance checks read.

So keep both in step. The footer never shows a dead link either way.

## Tracking page

The tracking form sends the customer's tracking number to a third-party lookup
service. The default is `https://t.17track.net/en#nums=` — carrier-agnostic and
opened in a new tab. Change it, or clear it to hide the form entirely, under:

- the Order lookup section on the tracking page, or
- Theme settings → Shipping, returns & trust → Tracking lookup URL.

If you use a tracking app (Parcel Panel, TrackingMore, AfterShip), put its
public tracking URL there instead so tracking numbers stay inside your stack.

## Google Merchant Center structured data

The theme emits its own JSON-LD instead of Shopify's `structured_data` filter,
because that filter cannot carry the shipping, returns and identifier fields
Merchant Center reads. It is rendered once from `layout/theme.liquid`, so no
entity is ever emitted twice — duplicate `Product` markup is a common cause of
disapprovals.

| Template | Markup |
|---|---|
| Every page | `Organization` (name, logo, address, telephone, email, contactPoint, sameAs) |
| Home | `WebSite` with `SearchAction` |
| Product | `Product` with one `Offer` per variant |
| Collection | `ItemList` of the products on the page |
| Product, collection, page, blog, article | `BreadcrumbList` |

Each `Offer` carries what Merchant Center and free listings look for:
`price`, `priceCurrency`, `priceValidUntil`, `availability`, `itemCondition`,
`url`, `sku`, `gtin`, `mpn`, `seller`, `shippingDetails` and
`hasMerchantReturnPolicy`.

### Set these per store

Theme settings → **Structured data (Google)**:

- **Ships to** — two-letter country codes. Must match the countries your
  shipping profile actually covers.
- **Shipping rate** — 0 for free shipping.
- **Handling and transit times** — these become `handlingTime` and
  `transitTime`, and Google compares them against your delivery promises.
- **Return method and return shipping cost** — the returns window itself comes
  from Theme settings → Shipping, returns & trust.
- **Item condition** — New unless you sell used or refurbished stock.

These values are published to Google. Merchant Center suspends accounts over
markup that contradicts the store, so they have to be true, not aspirational.

### Where the product fields come from

| Field | Source |
|---|---|
| `sku` | The variant's SKU |
| `gtin` | The variant's barcode — published only when it is 8, 12, 13 or 14 digits, so an internal code never goes out as an invalid GTIN |
| `mpn` | `custom.mpn` metafield on the variant, falling back to the product |
| `brand` | Product vendor, then the Brand fallback setting, then the store name |
| `category` | Product type |
| `aggregateRating` | The `reviews.rating` metafields a review app writes |

**Ratings are never faked.** The placeholder rating shown on the product page
(Theme settings → Product page) is display-only and is never marked up. The
`aggregateRating` field appears only once a reviews app has written real values,
which is what Google's policy requires.

### Fill in per product

Structured data can only publish what the product record holds. For the best
Merchant Center coverage, set on each product: **vendor** (brand), **product
type** (category), and a **barcode** per variant (GTIN). Products without a GTIN
still list, but match less well against Google's catalogue.

### Verify

After publishing, run a product URL through
[Google's Rich Results Test](https://search.google.com/test/rich-results) and
the [Schema Markup Validator](https://validator.schema.org/). In Merchant
Center, check Products → Diagnostics for identifier or landing-page mismatches.

## Auto menu

On by default. It renders Home, Shop (with a dropdown of the store's
collections), About Us, Contact Us, Track Your Order and Return and Refund
Policy — no navigation setup needed on a fresh store.

To use the store's own Shopify navigation instead, turn off
**Theme settings → Navigation (auto menu) → Use the automatic menu**. The
header section's Menu setting then takes over as in stock Dawn.

## Nothing is wired per store

The homepage carries no collection handles. `Featured products (auto)` resolves
a collection at render time — it tries the handles you list (`best-sellers`,
`featured`, …), then falls back to the store's own collections, skipping
`frontpage` and anything empty. `Collections (auto)` just lists what the store
has. Pick a collection explicitly and that always wins.

So the same homepage populates itself on a store with `best-sellers` and on one
whose collections are called `lampes-murales` and `suspensions`. On a store with
no products yet, both sections render nothing on the storefront and show a note
in the theme editor instead of an empty row.

## Sections added

`store-footer`, `hero-lighting`, `trust-strip`, `info-with-image`,
`contact-details`, `order-lookup`, `auto-featured-products`,
`auto-collection-list`, `legal-document`. All of Dawn's own sections are untouched
and still available — including its stock `featured-collection` and
`collection-list` if you would rather pick collections by hand.

## Product blocks added

`rating_line`, `stock_status`, `shipping_row`, `payment_icons`, `assurance`,
`usp_list` — add or reorder them in Customize → Product pages like any Dawn
block.
