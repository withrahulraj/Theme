# encoding: utf-8
require_relative 'render_test_helper'

puts "\n--- resolve-url ---"
out = check('resolve-url falls back when no page exists') {
  render_snippet('resolve-url', base_ctx.merge('handles' => 'contact,contact-us', 'fallback' => '/pages/contact'))
}
expect('  -> fallback used', out, '/pages/contact')

out = check('resolve-url finds a real page') {
  render_snippet('resolve-url', base_ctx('pages' => { 'contact-us' => { 'handle' => 'contact-us', 'url' => '/pages/contact-us' } })
    .merge('handles' => 'contact,contact-us', 'fallback' => '/pages/contact'))
}
expect('  -> real page wins', out, '/pages/contact-us')

puts "\n--- store-info ---"
%w[name address phone phone_href email map].each do |field|
  out = check("store-info #{field}") { render_snippet('store-info', base_ctx.merge('field' => field)) }
  puts "      => #{out.inspect}"
end
out = check('store-info honours overrides') {
  render_snippet('store-info', base_ctx('settings' => { 'store_phone_override' => '(555) 019-2211' }).merge('field' => 'phone_href'))
}
expect('  -> phone_href stripped', out, '5550192211')

out = check('store-info with an empty shop address') {
  render_snippet('store-info', base_ctx('shop' => shop('address' => {}, 'phone' => nil)).merge('field' => 'map'))
}
expect('  -> no map link', out.to_s.strip, '')

puts "\n--- auto-menu-links ---"
out = check('auto-menu-links builds records') { render_snippet('auto-menu-links', base_ctx) }
puts "      => #{out.inspect}"
expect('  -> six records', out.split('||').size.to_s, '6')
expect('  -> shop entry flagged', out, '/collections/all^^shop')

out = check('auto-menu-links without a refund policy') {
  render_snippet('auto-menu-links', base_ctx('shop' => shop('policies' => {})))
}
expect('  -> still resolves a policy link', out, 'policies/refund-policy')

puts "\n--- payment-icons ---"
out = check('payment-icons renders the full row') { render_snippet('payment-icons', base_ctx) }
expect('  -> ten badges', out.to_s.scan(/<li/).size.to_s, '10')
expect('  -> amex mapped to Shopify artwork', out, 'data-type="american_express"')
expect('  -> mastercard mapped', out, 'data-type="master"')
expect('  -> shop pay mapped', out, 'data-type="shopify_pay"')
expect('  -> link uses the inline fallback', out, 'payment-icons__svg" viewBox="0 0 38 24"')

out = check('payment-icons off') { render_snippet('payment-icons', base_ctx('settings' => { 'show_payment_icons' => false })) }
expect('  -> renders nothing', out.to_s.strip, '')

out = check('payment-icons with an unknown key') {
  render_snippet('payment-icons', base_ctx('settings' => { 'payment_icons_list' => 'visa, wibble_pay' }))
}
expect('  -> unknown key gets a wordmark fallback', out, 'WIBBLE PAY')

puts "\n--- product-rating-line ---"
product = { 'metafields' => { 'reviews' => {} },
            'selected_or_first_available_variant' => { 'available' => true, 'inventory_management' => 'shopify', 'inventory_quantity' => 6, 'inventory_policy' => 'deny' } }
out = check('rating line falls back to theme settings') { render_snippet('product-rating-line', base_ctx.merge('product' => product)) }
expect('  -> shows 4.7 / 5', out, '4.7 / 5')
expect('  -> four full stars', out.to_s.scan(/universal-icon--star"/).size.to_s, '4')
expect('  -> one half star', out.to_s.scan(/universal-icon--star_half/).size.to_s, '1')
expect('  -> review count', out, '(2,617+ Reviews)')

real = { 'metafields' => { 'reviews' => {
  'rating' => { 'value' => { 'rating' => 3.0, 'scale_max' => 5 } },
  'rating_count' => { 'value' => 42 } } } }
out = check('rating line prefers real review metafields') { render_snippet('product-rating-line', base_ctx.merge('product' => real)) }
expect('  -> shows 3.0 / 5', out, '3.0 / 5')
expect('  -> three full stars', out.to_s.scan(/universal-icon--star"/).size.to_s, '3')
expect('  -> two empty stars', out.to_s.scan(/universal-icon--star_empty/).size.to_s, '2')
expect('  -> real count', out, '(42 Reviews)')

puts "\n--- product-stock-status ---"
out = check('stock: low') { render_snippet('product-stock-status', base_ctx.merge('product' => product, 'section_id' => 'sec1')) }
expect('  -> almost sold out', out, 'Almost sold out')
expect('  -> low state class', out, 'product__stock--low')

untracked = { 'selected_or_first_available_variant' => { 'available' => true, 'inventory_management' => nil } }
out = check('stock: untracked inventory') { render_snippet('product-stock-status', base_ctx.merge('product' => untracked, 'section_id' => 'sec1')) }
expect('  -> in stock', out, 'product__stock--in')

soldout = { 'selected_or_first_available_variant' => { 'available' => false } }
out = check('stock: sold out') { render_snippet('product-stock-status', base_ctx.merge('product' => soldout, 'section_id' => 'sec1')) }
expect('  -> sold out', out, 'Sold out')

puts "\n--- product-shipping-row ---"
out = check('shipping row') { render_snippet('product-shipping-row', base_ctx) }
puts "      => #{out.gsub(/\s+/, ' ').strip[0, 200]}"
expect('  -> ships by a weekday', out.to_s.gsub(/\s+/, ' '), /Ships by <span class="product__shipping-strong">(Mon|Tue|Wed|Thu|Fri)/)
expect('  -> free shipping', out, 'Free Shipping')

puts "\n--- product-assurance ---"
out = check('assurance box') { render_snippet('product-assurance', base_ctx) }
expect('  -> tracking highlight', out, 'Each Package Includes Tracking.')

puts "\n--- store tokens ---"
body = '<p>Email [[email_link]] or call [[phone]]. We are open [[hours_days]], [[hours_time]]. ' \
       'You have [[returns_days]] days to return. Delivery takes [[delivery_min]]-[[delivery_max]] ' \
       'business days ([[handling_min]]-[[handling_max]] handling, [[transit_min]]-[[transit_max]] transit). ' \
       'We ship to [[shipping_countries]]. See our <a href="[[refund_policy_url]]">refund policy</a> ' \
       'or <a href="[[track_url]]">track an order</a>. (c) [[year]] [[store_name]].</p>'

out = check('tokens resolve from settings') { render_snippet('store-tokens', base_ctx.merge('content' => body)) }
expect('  -> email becomes a mailto link', out, '<a href="mailto:hello@lumen.test">hello@lumen.test</a>')
expect('  -> phone', out, '+1 555 0142')
expect('  -> working days', out, 'Monday – Friday')
expect('  -> working hours', out, '10:00 AM – 6:00 PM EST')
expect('  -> returns window from settings', out, 'You have 30 days to return')
expect('  -> delivery window is computed, not hardcoded', out, 'Delivery takes 6-11 business days')
expect('  -> handling and transit', out, '(1-2 handling, 5-9 transit)')
expect('  -> shipping countries', out, 'We ship to US, CA, GB, AU')
expect('  -> refund policy url', out, 'href="/policies/refund-policy"')
expect('  -> track order url', out, 'href="/pages/track-order"')
expect('  -> store name', out, 'Lumen Studio')
expect('  -> year', out, Time.now.year.to_s)
expect('  -> no tokens left behind', (out.to_s =~ /\[\[[a-z_]+\]\]/ ? 'leftover' : 'clean'), 'clean')

out = check('tokens follow a changed setting') {
  render_snippet('store-tokens',
    base_ctx('settings' => { 'trust_returns_days' => 60, 'sd_handling_max' => 3, 'sd_transit_max' => 14,
                             'store_hours_days' => 'Monday – Saturday',
                             'store_email_override' => 'help@brightloft.test' })
      .merge('content' => body))
}
expect('  -> new returns window', out, 'You have 60 days to return')
expect('  -> recomputed delivery window', out, 'Delivery takes 6-17 business days')
expect('  -> new hours', out, 'Monday – Saturday')
expect('  -> override email wins', out, 'mailto:help@brightloft.test')
expect('  -> old email gone', (out.to_s.include?('hello@lumen.test') ? 'stale' : 'updated'), 'updated')

out = check('tokens on a store with no phone or address') {
  render_snippet('store-tokens',
    base_ctx('shop' => shop('phone' => nil, 'address' => {}))
      .merge('content' => '<p>Call [[phone_link]] at [[address]].</p>'))
}
expect('  -> renders without raising', out, '<p>Call')
expect('  -> no empty tel link', (out.to_s.include?('href="tel:"') ? 'bad' : 'clean'), 'clean')

out = check('content with no tokens is passed through untouched') {
  render_snippet('store-tokens', base_ctx.merge('content' => '<p>Plain <strong>content</strong> &amp; markup.</p>'))
}
expect('  -> unchanged', out.to_s.strip, '<p>Plain <strong>content</strong> &amp; markup.</p>')

out = check('liquid in page content is not executed') {
  render_snippet('store-tokens',
    base_ctx.merge('content' => '<p>{{ shop.email }} {% assign x = 1 %}[[store_name]]</p>'))
}
expect('  -> liquid left as literal text', out, '{{ shop.email }}')
expect('  -> but real tokens still resolve', out, 'Lumen Studio')

puts "\n--- auto menus ---"
cols = [{ 'title' => 'Floor lamps', 'url' => '/collections/floor-lamps', 'handle' => 'floor-lamps', 'all_products_count' => 12 },
        { 'title' => 'Table lamps', 'url' => '/collections/table-lamps', 'handle' => 'table-lamps', 'all_products_count' => 8 }]
out = check('auto-menu-desktop') { render_snippet('auto-menu-desktop', base_ctx('collections' => cols)) }
expect('  -> six top level items', out.to_s.scan(/<li>/).size.to_s, (6 + 3).to_s)
expect('  -> shop dropdown present', out, 'HeaderMenu-auto-shop')
expect('  -> collection listed', out, '/collections/floor-lamps')

out = check('auto-menu-drawer') { render_snippet('auto-menu-drawer', base_ctx('collections' => cols)) }
expect('  -> drawer submenu present', out, 'menu-drawer__submenu')
expect('  -> track order link', out, 'Track Your Order')

out = check('auto-menu-desktop with no collections') { render_snippet('auto-menu-desktop', base_ctx('collections' => [])) }
expect('  -> shop degrades to a plain link', out, '<a')
expect('  -> no empty dropdown', (out.include?('HeaderMenu-auto-shop') ? 'yes' : 'no'), 'no')

puts "\n#{$failures.zero? ? 'ALL CHECKS PASSED' : "#{$failures} CHECK(S) FAILED"}"
exit($failures.zero? ? 0 : 1)
