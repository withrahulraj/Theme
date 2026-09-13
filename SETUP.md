# Universal lighting theme — setup

Shopify's official **Dawn 16.0.0**, with a store-driven header, footer, homepage,
support pages and product page layered on top. Nothing here is hardcoded to one
shop: the same theme ZIP can be uploaded to any number of lighting stores and it
fills itself in from that store's own settings.

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

Create these as normal Shopify pages. They pick up the right template
automatically, and the menu and footer start linking to them the moment they
exist.

| Page handle | Template | What it renders |
|---|---|---|
| `contact` | `page.contact` | Contact cards + contact form + trust strip |
| `track-order` | `page.track-order` | Tracking form + timeline + contact cards |
| `about-us` | `page` (default) | Your content + trust strip + newsletter |
| anything else | `page` (default) | Your content + trust strip + newsletter |

Alternative handles are recognised too, so an existing store does not need its
pages renamed: `contact-us`, `track-your-order`, `order-tracking`, `tracking`,
`about`, `our-story`, `faq`, `payment-policy`.

Until a page exists, links point at the handle above so nothing 404s silently
once you create it.

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

## Sections added

`store-footer`, `hero-lighting`, `trust-strip`, `info-with-image`,
`contact-details`, `order-lookup`. All of Dawn's own sections are untouched and
still available.

## Product blocks added

`rating_line`, `stock_status`, `shipping_row`, `payment_icons`, `assurance`,
`usp_list` — add or reorder them in Customize → Product pages like any Dawn
block.
