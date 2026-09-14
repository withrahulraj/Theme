# encoding: utf-8
require_relative 'render_test_helper'

cols = [{ 'title' => 'Floor lamps', 'url' => '/collections/floor-lamps', 'handle' => 'floor-lamps', 'all_products_count' => 12 }]

puts "\n--- store-footer ---"
out = check('store-footer renders on a fully configured store') { render_section('store-footer') }
expect('  -> store name', out, 'Lumen Studio')
expect('  -> address', out, '18 Kiln Road')
expect('  -> tel link', out, 'href="tel:+15550142"')
expect('  -> mailto link', out, 'mailto:hello@lumen.test')
expect('  -> working days', out, 'Monday – Friday')
expect('  -> working hours carry a timezone', out.to_s.gsub(/\s+/, ' '), /10:00 AM – 6:00 PM [A-Z]{2,5}/)
expect('  -> privacy policy', out, '/policies/privacy-policy')
expect('  -> refund policy', out, '/policies/refund-policy')
expect('  -> shipping policy', out, '/policies/shipping-policy')
expect('  -> terms of service', out, '/policies/terms-of-service')
expect('  -> help: contact', out, '/pages/contact')
expect('  -> help: about', out, '/pages/about-us')
expect('  -> help: track order', out, '/pages/track-order')
expect('  -> account link (accounts on)', out, '/account')
expect('  -> newsletter form', out, '<form>')
expect('  -> payment icons row', out, 'payment-icons')
expect('  -> copyright year', out, Time.now.year.to_s)

out = check('store-footer on a brand new store with nothing filled in') {
  render_section('store-footer',
    'shop' => shop('address' => {}, 'phone' => nil, 'email' => nil, 'policies' => {}, 'customer_accounts_enabled' => false))
}
expect('  -> no empty tel link', (out.to_s.include?('href="tel:"') ? 'bad' : 'clean'), 'clean')
expect('  -> policy fallback note', out, 'Policies are being updated.')
expect('  -> help links still render', out, '/pages/track-order')
expect('  -> payment icons still render', out, 'payment-icons__item')

out = check('store-footer picks up real pages when they exist') {
  render_section('store-footer', 'pages' => {
    'contact-us' => { 'handle' => 'contact-us', 'url' => '/pages/contact-us' },
    'faq' => { 'handle' => 'faq', 'url' => '/pages/faq' },
    'payment-policy' => { 'handle' => 'payment-policy', 'url' => '/pages/payment-policy' } })
}
expect('  -> real contact page', out, '/pages/contact-us')
expect('  -> FAQ link appears', out, '/pages/faq')
expect('  -> payment policy appears', out, '/pages/payment-policy')

puts "\n--- store-footer: policies kept as pages ---"
# brightloft's situation: Settings -> Policies is empty except privacy, and the
# legal documents live as pages instead. The column must still populate.
out = check('store-footer resolves policies from pages') {
  render_section('store-footer',
    'shop' => shop('policies' => {}),
    'pages' => {
      'refund-policy' => { 'handle' => 'refund-policy', 'url' => '/pages/refund-policy', 'title' => 'Return and Refund Policy' },
      'shipping-policy' => { 'handle' => 'shipping-policy', 'url' => '/pages/shipping-policy', 'title' => 'Shipping Policy' },
      'terms-of-service' => { 'handle' => 'terms-of-service', 'url' => '/pages/terms-of-service', 'title' => 'Terms of Service' },
      'payment-policy' => { 'handle' => 'payment-policy', 'url' => '/pages/payment-policy', 'title' => 'Payment Policy' },
    })
}
expect('  -> refund page linked', out, '/pages/refund-policy')
expect('  -> refund title from the page', out, 'Return and Refund Policy')
expect('  -> shipping page linked', out, '/pages/shipping-policy')
expect('  -> terms page linked', out, '/pages/terms-of-service')
expect('  -> payment policy linked', out, '/pages/payment-policy')
expect('  -> no "policies being updated" note', (out.to_s.include?('Policies are being updated') ? 'shown' : 'hidden'), 'hidden')

out = check('store-footer prefers a themed page over the untheme-able policy URL') {
  render_section('store-footer',
    'pages' => { 'refund-policy' => { 'handle' => 'refund-policy', 'url' => '/pages/refund-policy', 'title' => 'Return and Refund Policy' } })
}
expect('  -> page wins, so the layout matches the other policies', out, '/pages/refund-policy')
expect('  -> raw policy URL not used when a page exists',
       (out.to_s.include?('/policies/refund-policy') ? 'leaked' : 'clean'), 'clean')
expect('  -> policies without a page still fall back', out, '/policies/privacy-policy')

out = check('store-footer with neither policies nor pages') {
  render_section('store-footer', 'shop' => shop('policies' => {}))
}
expect('  -> falls back to the note', out, 'Policies are being updated.')

puts "\n--- policy template ---"
out = check('legal page renders from the page') {
  render_section('legal-document',
    'page' => { 'title' => 'Return and Refund Policy', 'content' => '<h2>30 days</h2><p>Send it back.</p>' })
}
expect('  -> title', out, 'Return and Refund Policy')
expect('  -> body', out, '<p>Send it back.</p>')
expect('  -> last updated line', out, 'Last updated')
expect('  -> contact details not repeated in a help box',
       (out.to_s.scan(/hello@lumen\.test/).size <= 2 ? 'once' : 'repeated'), 'once')

out = check('any page on the template is served') {
  render_section('legal-document',
    'page' => { 'title' => 'Payment Policy', 'content' => '<p>Cards and wallets.</p>' })
}
expect('  -> page title used', out, 'Payment Policy')
expect('  -> page content used', out, 'Cards and wallets.')

puts "\n--- universality: homepage on an unseen store ---"
def coll(handle, title, count, products = nil)
  products ||= (1..count).map { |i| { 'title' => "#{title} #{i}", 'url' => "/products/#{handle}-#{i}", 'handle' => "#{handle}-#{i}" } }
  { 'handle' => handle, 'title' => title, 'url' => "/collections/#{handle}",
    'all_products_count' => count, 'products' => products, 'featured_image' => nil }
end

# A store that happens to use the preferred handles.
named = [coll('frontpage', 'Home page', 1), coll('best-sellers', 'Best Sellers', 8), coll('new-arrivals', 'New Arrivals', 6)]
out = check('auto products picks the preferred handle') {
  render_section('auto-featured-products', 'collections' => named)
}
expect('  -> used best-sellers', out, '/products/best-sellers-1')
expect('  -> eight cards', out.to_s.scan(/grid__item/).size.to_s, '8')

# A store whose collections are named nothing like the defaults.
unnamed = [coll('frontpage', 'Home page', 2), coll('lampes-murales', 'Lampes murales', 5), coll('suspensions', 'Suspensions', 3)]
out = check('auto products falls back on a store with unfamiliar handles') {
  render_section('auto-featured-products', 'collections' => unnamed)
}
expect('  -> used the first real collection', out, '/products/lampes-murales-1')
expect('  -> skipped frontpage', (out.to_s.include?('/products/frontpage-') ? 'used' : 'skipped'), 'skipped')

out = check('a second row offsets so it does not repeat the first') {
  render_section('auto-featured-products',
    'section_settings' => { 'fallback_offset' => 1 }, 'collections' => unnamed)
}
expect('  -> used the second collection', out, '/products/suspensions-1')
expect('  -> not the first', (out.to_s.include?('/products/lampes-murales-') ? 'repeated' : 'distinct'), 'distinct')

out = check('an explicitly chosen collection always wins') {
  render_section('auto-featured-products',
    'section_settings' => { 'collection' => coll('sale', 'Sale', 4) }, 'collections' => named)
}
expect('  -> used the chosen collection', out, '/products/sale-1')

out = check('auto products on a store with no collections at all') {
  render_section('auto-featured-products', 'collections' => [])
}
expect('  -> renders no grid', (out.to_s.include?('grid__item') ? 'grid' : 'clean'), 'clean')
expect('  -> and no empty heading block on the storefront',
       (out.to_s.include?('This section fills itself in') ? 'note shown' : 'silent'), 'silent')

out = check('auto products on a store whose collections are all empty') {
  render_section('auto-featured-products', 'collections' => [coll('coming-soon', 'Coming soon', 0, [])])
}
expect('  -> renders no cards', (out.to_s.include?('grid__item') ? 'grid' : 'clean'), 'clean')

out = check('fewer products than columns does not leave gaps') {
  render_section('auto-featured-products', 'collections' => [coll('tiny', 'Tiny', 2)])
}
expect('  -> grid narrows to 2 columns', out, 'grid--2-col-desktop')
expect('  -> view all hidden when nothing is left over',
       (out.to_s.include?('button--primary') ? 'shown' : 'hidden'), 'hidden')

puts "\n--- universality: collection grid ---"
out = check('auto collection list uses the store\'s own collections') {
  render_section('auto-collection-list', 'collections' => unnamed)
}
expect('  -> first collection listed', out, '/collections/lampes-murales')
expect('  -> second collection listed', out, '/collections/suspensions')
expect('  -> frontpage excluded by default', (out.to_s.include?('/collections/frontpage') ? 'listed' : 'skipped'), 'skipped')
expect('  -> grid narrows to what exists', out, 'grid--2-col-desktop')

out = check('auto collection list hides empty collections') {
  render_section('auto-collection-list',
    'collections' => [coll('full', 'Full', 3), coll('empty', 'Empty', 0, [])])
}
expect('  -> empty one skipped', (out.to_s.include?('/collections/empty') ? 'listed' : 'skipped'), 'skipped')

out = check('auto collection list respects its limit') {
  render_section('auto-collection-list',
    'section_settings' => { 'collections_to_show' => 2 },
    'collections' => [coll('a', 'A', 1), coll('b', 'B', 1), coll('c', 'C', 1)])
}
expect('  -> only two cards', out.to_s.scan(/grid__item/).size.to_s, '2')

out = check('auto collection list on an empty store') {
  render_section('auto-collection-list', 'collections' => [])
}
expect('  -> renders nothing on the storefront', (out.to_s.include?('grid__item') ? 'grid' : 'clean'), 'clean')

puts "\n--- store details block on policy pages ---"
out = check('policy page carries trading details') {
  render_section('legal-document', 'page' => { 'title' => 'Shipping Policy', 'content' => '<p>Free.</p>' })
}
expect('  -> heading', out, 'Store information')
expect('  -> store name leads, like the footer', out, 'store-details__name')
expect('  -> store name', out, 'Lumen Studio')
expect('  -> address row', out, '18 Kiln Road')
expect('  -> phone as a tel link', out, 'href="tel:+15550142"')
expect('  -> email as a mailto link', out, 'mailto:hello@lumen.test')
expect('  -> working days', out, 'Monday – Friday')
expect('  -> hours carry a timezone', out.to_s.gsub(/\s+/, ' '), /10:00 AM – 6:00 PM [A-Z]{2,5}/)
expect('  -> four icon rows under the name', out.to_s.scan(/store-details__row/).size.to_s, '4')
expect('  -> icons used, as in the footer', out, 'universal-icon--pin')
expect('  -> labels kept for screen readers', out, 'visually-hidden')
expect('  -> no small print by default',
       (out.to_s.include?('kept up to date') ? 'shown' : 'gone'), 'gone')
expect('  -> timezone is fixed, not the store clock', out.to_s.gsub(/\s+/, ' '), '10:00 AM – 6:00 PM EST')

out = check('explicit timezone overrides the store default') {
  render_section('legal-document',
    'section_settings' => {}, 'page' => { 'title' => 'X', 'content' => '<p>y</p>' },
    'settings' => { 'store_hours_timezone' => 'PST' })
}
expect('  -> override used', out.to_s.gsub(/\s+/, ' '), '10:00 AM – 6:00 PM PST')

out = check('rows with no value are skipped, not printed empty') {
  render_section('legal-document',
    'shop' => shop('phone' => nil, 'address' => {}),
    'page' => { 'title' => 'X', 'content' => '<p>y</p>' })
}
expect('  -> no empty tel link', (out.to_s.include?('href="tel:"') ? 'bad' : 'clean'), 'clean')
expect('  -> address row dropped entirely',
       (out.to_s.include?('universal-icon--pin') ? 'shown' : 'hidden'), 'hidden')
expect('  -> email still shown', out, 'hello@lumen.test')

out = check('block can be switched off') {
  render_section('legal-document',
    'section_settings' => { 'show_store_details' => false },
    'page' => { 'title' => 'X', 'content' => '<p>y</p>' })
}
expect('  -> gone', (out.to_s.include?('store-details__list') ? 'shown' : 'hidden'), 'hidden')

out = check('no duplicate contact block on a policy page') {
  render_section('legal-document', 'page' => { 'title' => 'Shipping Policy', 'content' => '<p>Free.</p>' })
}
expect('  -> help box off by default',
       (out.to_s.include?('Still have a question') ? 'shown' : 'hidden'), 'hidden')
expect('  -> details block still present', out, 'store-details__list')
expect('  -> reads as content, not a card',
       (out.to_s.include?('<aside') ? 'aside' : 'inline'), 'inline')

puts "\n--- related products ---"
lamps = (1..5).map { |i| { 'id' => 100 + i, 'title' => "Lamp #{i}", 'url' => "/products/lamp-#{i}", 'handle' => "lamp-#{i}" } }
in_collection = coll('wall-lights', 'Wall Lights', 5, lamps)
current = { 'id' => 101, 'title' => 'Lamp 1', 'collections' => [in_collection] }

out = check('related products come from the product\'s own collection') {
  render_section('auto-related-products', 'product' => current, 'collections' => [in_collection])
}
expect('  -> heading', out, 'You may also like')
expect('  -> four cards', out.to_s.scan(/grid__item/).size.to_s, '4')
expect('  -> the product itself is excluded',
       (out.to_s.include?('/products/lamp-1"') ? 'included' : 'excluded'), 'excluded')

out = check('frontpage is skipped in favour of a real collection') {
  fp = coll('frontpage', 'Home page', 4)
  prod = { 'id' => 101, 'title' => 'Lamp 1', 'collections' => [fp, in_collection] }
  render_section('auto-related-products', 'product' => prod, 'collections' => [fp, in_collection])
}
expect('  -> used the real collection', out, '/products/lamp-2')

out = check('a product in no collection still gets suggestions') {
  prod = { 'id' => 999, 'title' => 'Orphan', 'collections' => [] }
  render_section('auto-related-products', 'product' => prod, 'collections' => [in_collection])
}
expect('  -> fell back to a store collection', out, 'grid__item')

out = check('a collection holding only this product renders nothing') {
  solo = coll('solo', 'Solo', 1, [{ 'id' => 101, 'title' => 'Lamp 1', 'url' => '/products/lamp-1' }])
  prod = { 'id' => 101, 'title' => 'Lamp 1', 'collections' => [solo] }
  render_section('auto-related-products', 'product' => prod, 'collections' => [solo])
}
expect('  -> no empty row', (out.to_s.include?('grid__item') ? 'row' : 'clean'), 'clean')

puts "\n--- contact-details ---"
out = check('contact-details renders all four cards') { render_section('contact-details') }
expect('  -> email card', out, 'hello@lumen.test')
expect('  -> phone card', out, '+1 555 0142')
expect('  -> hours card carries a timezone', out.to_s.gsub(/\s+/, ' '), /10:00 AM – 6:00 PM [A-Z]{2,5}/)
expect('  -> address card', out, '18 Kiln Road')
expect('  -> four-up grid', out, 'contact-details__grid--4')

out = check('contact-details with no store details at all') {
  render_section('contact-details', 'shop' => shop('address' => {}, 'phone' => nil, 'email' => nil))
}
expect('  -> guidance note', out, 'Settings → Store details')

puts "\n--- order-lookup ---"
out = check('order-lookup renders the tracking form') { render_section('order-lookup') }
expect('  -> tracking input', out, 'name="tracking_number"')
expect('  -> provider wired up', out, 'data-provider="https://t.17track.net/en#nums="')
expect('  -> account button', out, '/account')
expect('  -> contact button', out, '/pages/contact')
expect('  -> support email in footnote', out, 'hello@lumen.test')

out = check('order-lookup hides the form when no provider is set') {
  render_section('order-lookup', 'section_settings' => { 'tracking_provider_url' => '' })
}
expect('  -> no orphan form', (out.to_s.include?('tracking_number') ? 'bad' : 'clean'), 'clean')
expect('  -> support routes still offered', out, '/pages/contact')

puts "\n--- trust-strip ---"
out = check('trust-strip renders its preset') { render_section('trust-strip') }
expect('  -> four items', out.to_s.scan(/trust-strip__item/).size.to_s, '4')
expect('  -> free shipping', out, 'Free shipping')
expect('  -> grid class matches block count', out, 'trust-strip__grid--4')

puts "\n--- hero-lighting ---"
out = check('hero renders with a placeholder image') { render_section('hero-lighting') }
expect('  -> placeholder used', out, 'data-ph="hero-apparel-1"')
expect('  -> heading', out, 'Light that makes the room')
expect('  -> primary button falls back to all products', out, 'href="/collections/all"')
expect('  -> highlights', out.to_s.scan(/hero__usp"/).size.to_s, '3')

puts "\n--- info-with-image ---"
out = check('info with image renders') { render_section('info-with-image') }
expect('  -> placeholder used', out, 'data-ph="detailed-apparel-1"')
expect('  -> three points', out.to_s.scan(/info-media__list-item/).size.to_s, '3')
expect('  -> button falls back to all products', out, 'href="/collections/all"')


puts "\n--- main-page: store details without a custom template ---"
# The stock `page` template has to carry trading details on legal pages by
# itself. Assigning `page.policy` by hand on every store is exactly the setup
# step this theme exists to avoid, and Shopify's importer has dropped custom
# page templates before now.
out = check('main-page adds store details to a policy page') {
  render_section('main-page',
    'page' => { 'title' => 'Refund Policy', 'handle' => 'refund-policy', 'content' => '<p>30 days.</p>' })
}
expect('  -> page copy still renders', out, '30 days.')
expect('  -> details heading', out, 'Store information')
expect('  -> store name', out, 'Lumen Studio')
expect('  -> address', out, '18 Kiln Road')
expect('  -> phone', out, 'tel:+15550142')
expect('  -> email', out, 'mailto:hello@lumen.test')
expect('  -> working days', out, 'Monday – Friday')
expect('  -> hours carry a timezone', out.to_s.gsub(/\s+/, ' '), /10:00 AM – 6:00 PM [A-Z]{2,5}/)

%w[privacy-policy shipping-policy terms-of-service payment-policy return-and-refund-policy cookie-policy].each do |h|
  out = check("main-page detects /#{h}") {
    render_section('main-page', 'page' => { 'title' => h, 'handle' => h, 'content' => '<p>x</p>' })
  }
  expect("  -> #{h} gets details", out, 'store-details__name')
end

%w[about-us contact track-order faq home].each do |h|
  out = check("main-page leaves /#{h} alone") {
    render_section('main-page', 'page' => { 'title' => h, 'handle' => h, 'content' => '<p>x</p>' })
  }
  expect("  -> #{h} has no details block", (out.to_s.include?('store-details__name') ? 'present' : 'absent'), 'absent')
end

out = check('main-page "always" mode overrides detection') {
  render_section('main-page', 'section_settings' => { 'store_details_mode' => 'always' },
    'page' => { 'title' => 'About us', 'handle' => 'about-us', 'content' => '<p>x</p>' })
}
expect('  -> details forced on', out, 'store-details__name')

out = check('main-page "never" mode overrides detection') {
  render_section('main-page', 'section_settings' => { 'store_details_mode' => 'never' },
    'page' => { 'title' => 'Refund Policy', 'handle' => 'refund-policy', 'content' => '<p>x</p>' })
}
expect('  -> details forced off', (out.to_s.include?('store-details__name') ? 'present' : 'absent'), 'absent')

out = check('main-page still substitutes tokens') {
  render_section('main-page',
    'page' => { 'title' => 'Shipping Policy', 'handle' => 'shipping-policy',
                'content' => '<p>Arrives in [[delivery_min]]–[[delivery_max]] business days.</p>' })
}
expect('  -> no raw token left', (out.to_s.include?('[[') ? 'raw' : 'clean'), 'clean')
expect('  -> delivery window filled in', out, '4–7 business days')


puts "\n--- built-in policy copy fills an empty page ---"
# The whole point: a new store creates the page and stops there.
{
  'privacy-policy'   => 'What we collect',
  'refund-policy'    => 'days to change your mind',
  'shipping-policy'  => 'Where we ship',
  'payment-policy'   => 'How you can pay',
  'terms-of-service' => 'About these terms',
}.each do |handle, marker|
  out = check("empty /#{handle} fills itself in") {
    render_section('main-page', 'page' => { 'title' => handle, 'handle' => handle, 'content' => '' })
  }
  expect("  -> document rendered", out, marker)
  expect("  -> no raw token left", (out.to_s.include?('[[') ? 'raw' : 'clean'), 'clean')
  expect("  -> store details follow it", out, 'store-details__name')
end

%w[refund-policy return-policy returns return-and-refund-policy].each do |handle|
  out = check("alias /#{handle} resolves to the refund document") {
    render_section('main-page', 'page' => { 'title' => handle, 'handle' => handle, 'content' => '' })
  }
  expect("  -> refund copy", out, 'days to change your mind')
end

out = check('a page body overrides the built-in copy') {
  render_section('main-page',
    'page' => { 'title' => 'Shipping Policy', 'handle' => 'shipping-policy',
                'content' => '<p>We ship by carrier pigeon.</p>' })
}
expect('  -> merchant copy used', out, 'carrier pigeon')
expect('  -> built-in copy not appended', (out.to_s.include?('Where we ship') ? 'both' : 'override'), 'override')

%w[contact faq shipping-information our-team random-page].each do |handle|
  out = check("empty /#{handle} stays empty") {
    render_section('main-page', 'page' => { 'title' => handle, 'handle' => handle, 'content' => '' })
  }
  expect("  -> no policy copy invented", (out.to_s.include?('<h2>') ? 'invented' : 'empty'), 'empty')
end

%w[about-us about our-story].each do |handle|
  out = check("empty /#{handle} fills itself in") {
    render_section('main-page', 'page' => { 'title' => 'About Us', 'handle' => handle, 'content' => '' })
  }
  expect("  -> about copy rendered", out, 'Light is the cheapest renovation')
  expect("  -> no raw token left", (out.to_s.include?('[[') ? 'raw' : 'clean'), 'clean')
  expect("  -> store name filled in", out, 'Lumen Studio')
  expect("  -> no trading details block on About", (out.to_s.include?('store-details__name') ? 'present' : 'absent'), 'absent')
end

out = check('a written About replaces the built-in draft') {
  render_section('main-page',
    'page' => { 'title' => 'About Us', 'handle' => 'about-us', 'content' => '<p>We started in a garage.</p>' })
}
expect('  -> merchant copy used', out, 'garage')
expect('  -> draft not appended', (out.to_s.include?('cheapest renovation') ? 'both' : 'override'), 'override')

out = check('the legal-document template fills an empty page too') {
  render_section('legal-document', 'page' => { 'title' => 'Privacy Policy', 'handle' => 'privacy-policy', 'content' => '' })
}
expect('  -> document rendered', out, 'What we collect')
expect('  -> no raw token left', (out.to_s.include?('[[') ? 'raw' : 'clean'), 'clean')

out = check('shipping-policy fills in the delivery window') {
  render_section('main-page', 'page' => { 'title' => 'Shipping Policy', 'handle' => 'shipping-policy', 'content' => '' })
}
expect('  -> handling window', out, '1–2 business days')
expect('  -> transit window', out, '3–5 business days')
expect('  -> total window', out, '4–7 business days')
expect('  -> store details follow the copy', out, 'store-details__name')

out = check('terms-of-service fills in the governing state') {
  render_section('main-page', 'page' => { 'title' => 'Terms of Service', 'handle' => 'terms-of-service', 'content' => '' })
}
expect('  -> governing law names the jurisdiction', out, 'governed by the laws of New York, United States')

out = check('terms-of-service still reads on a store with no address') {
  render_section('main-page', 'shop' => shop('address' => {}),
    'page' => { 'title' => 'Terms of Service', 'handle' => 'terms-of-service', 'content' => '' })
}
expect('  -> no hole in the sentence', (out.to_s.include?('laws of ,') ? 'broken' : 'clean'), 'clean')
expect('  -> falls back to a real jurisdiction', out, 'governed by the laws of the United States')

puts "\n--- seo-description ---"
# page_description falls back to the page body, so tokens would otherwise reach
# Google's snippet and the social preview card verbatim.
out = check('seo-description substitutes tokens') {
  render_snippet('seo-description', base_ctx.merge(
    'source' => '<h2>Where we ship</h2><p>[[store_name]] ships in [[delivery_min]]–[[delivery_max]] business days.</p>'))
}
expect('  -> no raw token', (out.to_s.include?('[[') ? 'raw' : 'clean'), 'clean')
expect('  -> store name substituted', out, 'Lumen Studio')
expect('  -> delivery window substituted', out, '4–7 business days')
expect('  -> markup stripped', (out.to_s.include?('<') ? 'markup' : 'plain'), 'plain')
expect('  -> no double spaces', (out.to_s.include?('  ') ? 'padded' : 'tidy'), 'tidy')

out = check('seo-description on a page with no description') {
  render_snippet('seo-description', base_ctx.merge('source' => nil))
}
expect('  -> renders nothing', out.to_s.strip, '')

puts "\n#{$failures.zero? ? 'ALL SECTION CHECKS PASSED' : "#{$failures} CHECK(S) FAILED"}"
exit($failures.zero? ? 0 : 1)
