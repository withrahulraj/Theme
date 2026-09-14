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
out = check('policy page renders from the policy object') {
  render_section('main-policy',
    'policy' => { 'title' => 'Return and Refund Policy', 'body' => '<h2>30 days</h2><p>Send it back.</p>' })
}
expect('  -> title', out, 'Return and Refund Policy')
expect('  -> body', out, '<p>Send it back.</p>')
expect('  -> last updated line', out, 'Last updated')
expect('  -> contact details not repeated in a help box',
       (out.to_s.scan(/hello@lumen\.test/).size <= 2 ? 'once' : 'repeated'), 'once')

out = check('policy template also serves a plain page') {
  render_section('main-policy',
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
  render_section('main-policy', 'policy' => { 'title' => 'Shipping Policy', 'body' => '<p>Free.</p>' })
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
  render_section('main-policy',
    'section_settings' => {}, 'policy' => { 'title' => 'X', 'body' => '<p>y</p>' },
    'settings' => { 'store_hours_timezone' => 'PST' })
}
expect('  -> override used', out.to_s.gsub(/\s+/, ' '), '10:00 AM – 6:00 PM PST')

out = check('rows with no value are skipped, not printed empty') {
  render_section('main-policy',
    'shop' => shop('phone' => nil, 'address' => {}),
    'policy' => { 'title' => 'X', 'body' => '<p>y</p>' })
}
expect('  -> no empty tel link', (out.to_s.include?('href="tel:"') ? 'bad' : 'clean'), 'clean')
expect('  -> address row dropped entirely',
       (out.to_s.include?('universal-icon--pin') ? 'shown' : 'hidden'), 'hidden')
expect('  -> email still shown', out, 'hello@lumen.test')

out = check('block can be switched off') {
  render_section('main-policy',
    'section_settings' => { 'show_store_details' => false },
    'policy' => { 'title' => 'X', 'body' => '<p>y</p>' })
}
expect('  -> gone', (out.to_s.include?('store-details__list') ? 'shown' : 'hidden'), 'hidden')

out = check('no duplicate contact block on a policy page') {
  render_section('main-policy', 'policy' => { 'title' => 'Shipping Policy', 'body' => '<p>Free.</p>' })
}
expect('  -> help box off by default',
       (out.to_s.include?('Still have a question') ? 'shown' : 'hidden'), 'hidden')
expect('  -> details block still present', out, 'store-details__list')
expect('  -> reads as content, not a card',
       (out.to_s.include?('<aside') ? 'aside' : 'inline'), 'inline')

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

puts "\n#{$failures.zero? ? 'ALL SECTION CHECKS PASSED' : "#{$failures} CHECK(S) FAILED"}"
exit($failures.zero? ? 0 : 1)
