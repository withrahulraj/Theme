# encoding: utf-8
require 'date'
require_relative 'render_test_helper'
require 'json'

# Pulls every <script type="application/ld+json"> out of rendered output and
# parses it. Malformed commas in Liquid-built JSON are the usual failure, and
# they are invisible until something parses the result.
def ld_blocks(html, label)
  blocks = html.to_s.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten
  blocks.map do |raw|
    begin
      JSON.parse(raw)
    rescue JSON::ParserError => e
      $failures += 1
      puts "FAIL  #{label}: JSON-LD does not parse\n      #{e.message}\n      #{raw.strip[0, 400]}"
      nil
    end
  end.compact
end

def variant(over = {})
  { 'id' => 1, 'title' => 'Small', 'sku' => 'LMP-EGG-S', 'barcode' => '5901234123457',
    'price' => 14995, 'available' => true, 'url' => '/products/egg-lamp?variant=1',
    'featured_image' => '//cdn.test/variant-small.jpg',
    'inventory_management' => 'shopify', 'inventory_quantity' => 6, 'inventory_policy' => 'deny',
    'metafields' => { 'custom' => {} } }.merge(over)
end

def egg_lamp(over = {})
  {
    'id' => 900, 'title' => 'Floor Lamp with Egg Shape',
    'description' => '<p>A sculptural <strong>egg-shaped</strong> floor lamp.</p>',
    'url' => '/products/egg-lamp', 'vendor' => 'Lumen', 'type' => 'Floor lamps',
    'images' => ['//cdn.test/1.jpg', '//cdn.test/2.jpg'],
    'featured_image' => '//cdn.test/1.jpg',
    'metafields' => { 'reviews' => {}, 'custom' => {} },
    'variants' => [variant],
    'selected_or_first_available_variant' => variant,
  }.merge(over)
end

puts "\n--- Product: single variant ---"
out = check('product markup renders') {
  render_snippet('structured-data-product', base_ctx.merge('product' => egg_lamp))
}
docs = ld_blocks(out, 'single variant')
prod = docs.first || {}
puts "PASS  product JSON-LD parses" if prod.any?
expect('  -> @type Product', prod['@type'].to_s, 'Product')
expect('  -> name', prod['name'].to_s, 'Floor Lamp with Egg Shape')
expect('  -> description is plain text', prod['description'].to_s, 'A sculptural egg-shaped floor lamp.')
expect('  -> absolute image URLs', (prod['image'] || []).first.to_s, 'https://cdn.test/1.jpg')
expect('  -> brand', prod.dig('brand', 'name').to_s, 'Lumen')
expect('  -> category', prod['category'].to_s, 'Floor lamps')

offer = (prod['offers'] || []).first || {}
expect('  -> one offer', (prod['offers'] || []).size.to_s, '1')
expect('  -> price is a number', offer['price'].class.to_s, 'Float')
expect('  -> price value', offer['price'].to_s, '149.95')
expect('  -> currency', offer['priceCurrency'].to_s, 'USD')
expect('  -> availability', offer['availability'].to_s, 'https://schema.org/InStock')
expect('  -> itemCondition', offer['itemCondition'].to_s, 'https://schema.org/NewCondition')
expect('  -> sku', offer['sku'].to_s, 'LMP-EGG-S')
expect('  -> gtin from a valid barcode', offer['gtin'].to_s, '5901234123457')
expect('  -> priceValidUntil is in the future',
       (Date.parse(offer['priceValidUntil']) > Date.today ? 'future' : 'past'), 'future')
expect('  -> offer url is absolute', offer['url'].to_s, 'https://lumen.test/products/egg-lamp?variant=1')
expect('  -> seller links to the Organization', offer.dig('seller', '@id').to_s, 'https://lumen.test/#organization')

ship = offer['shippingDetails'] || {}
expect('  -> shippingDetails type', ship['@type'].to_s, 'OfferShippingDetails')
expect('  -> free shipping rate', ship.dig('shippingRate', 'value').to_s, '0')
expect('  -> ships to one country by default', (ship['shippingDestination'] || []).size.to_s, '1')
expect('  -> and it is the US', ship['shippingDestination'].first['addressCountry'].to_s, 'US')
expect('  -> handling time', ship.dig('deliveryTime', 'handlingTime', 'maxValue').to_s, '2')
expect('  -> transit time', ship.dig('deliveryTime', 'transitTime', 'maxValue').to_s, '5')
expect('  -> transit minimum', ship.dig('deliveryTime', 'transitTime', 'minValue').to_s, '3')

ret = offer['hasMerchantReturnPolicy'] || {}
expect('  -> return policy type', ret['@type'].to_s, 'MerchantReturnPolicy')
expect('  -> 30 day window', ret['merchantReturnDays'].to_s, '30')
expect('  -> finite window category', ret['returnPolicyCategory'].to_s, 'MerchantReturnFiniteReturnWindow')
expect('  -> free returns', ret['returnFees'].to_s, 'https://schema.org/FreeReturn')
expect('  -> returns apply to the same country', (ret['applicableCountry'] || []).size.to_s, '1')
expect('  -> business days declared', (ship.dig('deliveryTime', 'businessDays', 'dayOfWeek') || []).size.to_s, '5')
expect('  -> weekends excluded',
       ((ship.dig('deliveryTime', 'businessDays', 'dayOfWeek') || []).any? { |d| d =~ /Saturday|Sunday/ } ? 'included' : 'excluded'),
       'excluded')
expect('  -> cut-off time published', ship.dig('deliveryTime', 'cutoffTime').to_s, '17:00:00-05:00')
expect('  -> return policy country', (ret['returnPolicyCountry'] || []).first.to_s, 'US')
expect('  -> refund type', ret['refundType'].to_s, 'FullRefund')

puts "\n--- Product: a store that does ship internationally ---"
out = check('multi-country shipping markup') {
  render_snippet('structured-data-product',
    base_ctx('settings' => { 'sd_shipping_countries' => 'US, CA, GB, AU' }).merge('product' => egg_lamp))
}
prod = (ld_blocks(out, 'multi country').first || {})
offer = (prod['offers'] || []).first || {}
dests = offer.dig('shippingDetails', 'shippingDestination') || []
expect('  -> four destinations', dests.size.to_s, '4')
expect('  -> in the order listed', dests.map { |d| d['addressCountry'] }.inspect, '["US", "CA", "GB", "AU"]')
expect('  -> returns cover the same four', (offer.dig('hasMerchantReturnPolicy', 'applicableCountry') || []).size.to_s, '4')

puts "\n--- Product: multi-variant, mixed availability ---"
multi = egg_lamp('variants' => [
  variant,
  variant('id' => 2, 'title' => 'Medium', 'sku' => 'LMP-EGG-M', 'price' => 19995,
          'url' => '/products/egg-lamp?variant=2', 'barcode' => ''),
  variant('id' => 3, 'title' => 'Large', 'sku' => 'LMP-EGG-L', 'price' => 24995,
          'available' => false, 'url' => '/products/egg-lamp?variant=3', 'barcode' => 'NOTAGTIN123'),
])
out = check('multi-variant markup renders') {
  render_snippet('structured-data-product', base_ctx.merge('product' => multi))
}
prod = (ld_blocks(out, 'multi variant').first || {})
offers = prod['offers'] || []
expect('  -> three offers', offers.size.to_s, '3')
expect('  -> prices differ per variant', offers.map { |o| o['price'] }.inspect, '[149.95, 199.95, 249.95]')
expect('  -> sold-out variant marked OutOfStock', offers[2]['availability'].to_s, 'OutOfStock')
expect('  -> blank barcode emits no gtin', (offers[1].key?('gtin') ? 'present' : 'absent'), 'absent')
expect('  -> non-numeric barcode emits no gtin', (offers[2].key?('gtin') ? 'present' : 'absent'), 'absent')

puts "\n--- Product: variants with no SKU ---"
no_sku = egg_lamp('variants' => [variant('sku' => nil), variant('id' => 2, 'sku' => '', 'url' => '/products/egg-lamp?variant=2')])
out = check('offers still carry an identifier') {
  render_snippet('structured-data-product', base_ctx.merge('product' => no_sku))
}
skus = ((ld_blocks(out, 'no sku').first || {})['offers'] || []).map { |o| o['sku'] }
expect('  -> every offer has a sku', (skus.all? { |s| s.to_s != '' } ? 'all' : 'missing'), 'all')
expect('  -> generated from the store name', skus.first.to_s, /\ALUM-/)
expect('  -> unique per variant', (skus.uniq.size == skus.size ? 'unique' : 'duplicated'), 'unique')

puts "\n--- Product: ratings ---"
expect('  -> no aggregateRating without real reviews', (prod.key?('aggregateRating') ? 'present' : 'absent'), 'absent')

rated = egg_lamp('metafields' => { 'reviews' => {
  'rating' => { 'value' => { 'rating' => 4.7, 'scale_max' => 5 } },
  'rating_count' => { 'value' => 2617 } }, 'custom' => {} })
out = check('rated product markup renders') {
  render_snippet('structured-data-product', base_ctx.merge('product' => rated))
}
prod = (ld_blocks(out, 'rated').first || {})
agg = prod['aggregateRating'] || {}
expect('  -> aggregateRating published for real reviews', agg['@type'].to_s, 'AggregateRating')
expect('  -> ratingValue', agg['ratingValue'].to_s, '4.7')
expect('  -> ratingCount', agg['ratingCount'].to_s, '2617')

out = check('ratings can be switched off') {
  render_snippet('structured-data-product',
    base_ctx('settings' => { 'sd_ratings_enabled' => false }).merge('product' => rated))
}
prod = (ld_blocks(out, 'ratings off').first || {})
expect('  -> respected', (prod.key?('aggregateRating') ? 'present' : 'absent'), 'absent')

puts "\n--- Product: shipping and returns switched off ---"
out = check('markup without shipping or returns') {
  render_snippet('structured-data-product',
    base_ctx('settings' => { 'sd_shipping_enabled' => false, 'sd_returns_enabled' => false })
      .merge('product' => egg_lamp))
}
prod = (ld_blocks(out, 'no shipping').first || {})
offer = (prod['offers'] || []).first || {}
expect('  -> no shippingDetails', (offer.key?('shippingDetails') ? 'present' : 'absent'), 'absent')
expect('  -> no return policy', (offer.key?('hasMerchantReturnPolicy') ? 'present' : 'absent'), 'absent')
expect('  -> offer still valid', offer['price'].to_s, '149.95')

puts "\n--- Product: paid returns ---"
out = check('paid return markup') {
  render_snippet('structured-data-product',
    base_ctx('settings' => { 'sd_return_fees' => 'ReturnShippingFees', 'sd_return_fee_amount' => '9.95' })
      .merge('product' => egg_lamp))
}
prod = (ld_blocks(out, 'paid returns').first || {})
ret = prod.dig('offers', 0, 'hasMerchantReturnPolicy') || {}
expect('  -> fees declared', ret['returnFees'].to_s, 'ReturnShippingFees')
expect('  -> fee amount', ret.dig('returnShippingFeesAmount', 'value').to_s, '9.95')

puts "\n--- Organization ---"
out = check('organization markup renders') { render_snippet('structured-data-organization', base_ctx) }
org = (ld_blocks(out, 'organization').first || {})
expect('  -> @id is stable', org['@id'].to_s, 'https://lumen.test/#organization')
expect('  -> name', org['name'].to_s, 'Lumen Studio')
expect('  -> telephone', org['telephone'].to_s, '+1 555 0142')
expect('  -> email', org['email'].to_s, 'hello@lumen.test')
expect('  -> postal address', org.dig('address', 'streetAddress').to_s, '18 Kiln Road')
expect('  -> locality', org.dig('address', 'addressLocality').to_s, 'Brooklyn')
expect('  -> contact point', org.dig('contactPoint', 'contactType').to_s, 'customer support')
expect('  -> sameAs empty when no socials', (org['sameAs'] || []).size.to_s, '0')

out = check('organization with socials') {
  render_snippet('structured-data-organization',
    base_ctx('settings' => { 'social_instagram_link' => 'https://instagram.com/lumen',
                             'social_facebook_link' => 'https://facebook.com/lumen' }))
}
org = (ld_blocks(out, 'organization socials').first || {})
expect('  -> two sameAs entries', (org['sameAs'] || []).size.to_s, '2')

out = check('organization on a store with no address') {
  render_snippet('structured-data-organization',
    base_ctx('shop' => shop('address' => {}, 'phone' => nil, 'email' => nil)))
}
org = (ld_blocks(out, 'organization bare').first || {})
expect('  -> address omitted rather than half-empty', (org.key?('address') ? 'present' : 'absent'), 'absent')
expect('  -> still names the store', org['name'].to_s, 'Lumen Studio')

puts "\n--- Breadcrumbs ---"
out = check('product breadcrumbs') {
  render_snippet('structured-data-breadcrumbs',
    base_ctx('request' => { 'page_type' => 'product', 'origin' => 'https://lumen.test' })
      .merge('product' => egg_lamp,
             'collection' => { 'title' => 'Floor lamps', 'url' => '/collections/floor-lamps', 'handle' => 'floor-lamps' }))
}
crumbs = (ld_blocks(out, 'breadcrumbs').first || {})
items = crumbs['itemListElement'] || []
expect('  -> three levels', items.size.to_s, '3')
expect('  -> positions ascend', items.map { |i| i['position'] }.inspect, '[1, 2, 3]')
expect('  -> home first', items[0]['name'].to_s, '[universal.nav.home]')
expect('  -> collection second', items[1]['item'].to_s, 'https://lumen.test/collections/floor-lamps')
expect('  -> product last', items[2]['item'].to_s, 'https://lumen.test/products/egg-lamp')

out = check('page breadcrumbs') {
  render_snippet('structured-data-breadcrumbs',
    base_ctx('request' => { 'page_type' => 'page', 'origin' => 'https://lumen.test' })
      .merge('page' => { 'title' => 'Track Your Order', 'url' => '/pages/track-order' }))
}
items = ((ld_blocks(out, 'page breadcrumbs').first || {})['itemListElement'] || [])
expect('  -> two levels', items.size.to_s, '2')
expect('  -> page name', items[1]['name'].to_s, 'Track Your Order')

out = check('breadcrumbs on a template with no trail') {
  render_snippet('structured-data-breadcrumbs',
    base_ctx('request' => { 'page_type' => 'cart', 'origin' => 'https://lumen.test' }))
}
expect('  -> nothing emitted', out.to_s.include?('BreadcrumbList') ? 'emitted' : 'clean', 'clean')

puts "\n--- Collection ItemList ---"
products = (1..3).map { |i| { 'title' => "Lamp #{i}", 'url' => "/products/lamp-#{i}" } }
out = check('collection markup renders') {
  render_snippet('structured-data-collection',
    base_ctx.merge('collection' => { 'title' => 'Floor lamps', 'url' => '/collections/floor-lamps',
                                     'products' => products }))
}
list = (ld_blocks(out, 'collection').first || {})
expect('  -> ItemList', list['@type'].to_s, 'ItemList')
expect('  -> item count', list['numberOfItems'].to_s, '3')
expect('  -> entries', (list['itemListElement'] || []).size.to_s, '3')
expect('  -> absolute URLs', list['itemListElement'][0]['url'].to_s, 'https://lumen.test/products/lamp-1')

out = check('empty collection') {
  render_snippet('structured-data-collection',
    base_ctx.merge('collection' => { 'title' => 'Empty', 'url' => '/collections/empty', 'products' => [] }))
}
expect('  -> nothing emitted', out.to_s.include?('ItemList') ? 'emitted' : 'clean', 'clean')

puts "\n--- Dispatcher ---"
out = check('dispatcher on the homepage') {
  render_snippet('structured-data', base_ctx('request' => { 'page_type' => 'index', 'origin' => 'https://lumen.test' }))
}
docs = ld_blocks(out, 'dispatcher index')
types = docs.map { |d| d['@type'] }
expect('  -> Organization + WebSite', types.sort.inspect, '["Organization", "WebSite"]')
site = docs.find { |d| d['@type'] == 'WebSite' }
expect('  -> search action target', site.dig('potentialAction', 'target', 'urlTemplate').to_s,
       'https://lumen.test/search?q={search_term_string}')
expect('  -> no Product on the homepage', types.include?('Product') ? 'leaked' : 'clean', 'clean')

out = check('dispatcher on a product page') {
  render_snippet('structured-data',
    base_ctx('request' => { 'page_type' => 'product', 'origin' => 'https://lumen.test',
                            'locale' => { 'endonym_name' => 'English' } })
      .merge('product' => egg_lamp, 'collection' => {}))
}
types = ld_blocks(out, 'dispatcher product').map { |d| d['@type'] }
expect('  -> Organization, Breadcrumbs, Product', types.sort.inspect,
       '["BreadcrumbList", "Organization", "Product"]')
expect('  -> exactly one Product', types.count('Product').to_s, '1')

out = check('dispatcher switched off') {
  render_snippet('structured-data', base_ctx('settings' => { 'sd_enabled' => false }))
}
expect('  -> nothing emitted', out.to_s.strip.empty? ? 'clean' : 'emitted', 'clean')

puts "\n#{$failures.zero? ? 'ALL STRUCTURED DATA CHECKS PASSED' : "#{$failures} CHECK(S) FAILED"}"
exit($failures.zero? ? 0 : 1)
