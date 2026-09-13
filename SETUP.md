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
