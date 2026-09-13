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
expect('  -> working hours', out, '10:00 AM – 6:00 PM EST')
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

puts "\n--- contact-details ---"
out = check('contact-details renders all four cards') { render_section('contact-details') }
expect('  -> email card', out, 'hello@lumen.test')
expect('  -> phone card', out, '+1 555 0142')
expect('  -> hours card', out, '10:00 AM – 6:00 PM EST')
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
