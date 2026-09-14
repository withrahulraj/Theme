# Store content

A theme carries templates and sections. It does not carry pages.

Uploading the theme ZIP to a new store gives that store the layouts, but the
pages themselves are store content and have to exist before anything renders.
That is why policy pages look wrong — or 404 — on a store the theme was only
uploaded to.

## The policies need no content at all

The five legal documents are built into the theme
(`snippets/policy-body-*.liquid`). **Create the page, leave the body empty, and
the document appears.** Nothing to paste.

| Create a page titled | Handle | Leave body |
| --- | --- | --- |
| Privacy Policy | `privacy-policy` | empty |
| Return and Refund Policy | `refund-policy` | empty |
| Shipping Policy | `shipping-policy` | empty |
| Payment Policy | `payment-policy` | empty |
| Terms of Service | `terms-of-service` | empty |

Common alternatives are recognised too — `returns`, `return-policy`,
`terms`, `terms-and-conditions`, `delivery-policy`, `privacy`.

## Changing the text

**One store only** — type into the page body in Content → Pages. Anything there
replaces the built-in document completely. Clear the body again to go back to
the built-in one. Nothing else to switch.

**Every store** — edit `snippets/policy-body-*.liquid` and re-upload the theme.
Every store on that version follows.

Either way, do not hardcode a store name, email, address, delivery window or
state. Those are written as `[[placeholders]]` that the theme substitutes from
each store's own settings, which is what makes one document correct everywhere:

| Placeholder | Becomes |
| --- | --- |
| `[[store_name]]` | Settings → Store details → store name |
| `[[jurisdiction]]` | The store's state and country, for the governing-law clause |
| `[[handling_min]]`–`[[handling_max]]` | Theme settings → Shipping |
| `[[transit_min]]`–`[[transit_max]]` | Theme settings → Shipping |
| `[[delivery_min]]`–`[[delivery_max]]` | The two above, added together |
| `[[returns_days]]` | Theme settings → Returns |
| `[[timezone]]` | Theme settings → Store information |
| `[[refund_policy_url]]` and friends | Resolved to whichever exists on this store |

`validate_templates.py` fails the build on a hardcoded store name, email
address or state in that copy, and on a placeholder the theme does not
substitute.

## The rest of the pages

`about-us.html` is here rather than in the theme because the story is yours,
not a template — paste it in HTML view and rewrite it. Contact and Track Your
Order are rendered entirely by theme sections, so their bodies stay empty.

`pages.json` lists all eight pages with handles and templates.

## Setting up a new store

1. Upload the theme ZIP and publish it.
2. Fill in **Settings → Store details** — name, address, phone, support email.
   Everything on the storefront reads from here.
3. Create the pages in `pages.json`. Title and handle exactly as listed — the
   handle is what the footer links to and what selects the document.
4. Set the theme template where a row names one, in the page editor's **Theme
   template** dropdown. Policy pages work without it, so this is cosmetic.
5. Check the footer. A missing policy link means the handle does not match.

Only About Us needs anything typed into it.
