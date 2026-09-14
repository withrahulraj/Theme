# encoding: utf-8
require 'liquid'
require 'json'

THEME = File.expand_path('..', __dir__)

# --- Shopify-ish filters used by the snippets under test -------------------
module ShopifyFilters
  def payment_type_svg_tag(type, _opts = {})
    known = %w[visa master american_express paypal shopify_pay apple_pay google_pay
               unionpay jcb discover diners_club maestro elo klarna afterpay amazon
               bancontact ideal sofort venmo]
    known.include?(type) ? "<svg class=\"pay\" data-type=\"#{type}\"></svg>" : ''
  end
  def inline_asset_content(file) "<svg data-asset=\"#{file}\"></svg>" end
  def placeholder_svg_tag(name, cls = '') "<svg class=\"#{cls}\" data-ph=\"#{name}\"></svg>" end
  def asset_url(f) "//cdn.test/#{f}" end
  def stylesheet_tag(url) "<link href=\"#{url}\">" end
  def image_url(img, _opts = {}) img.to_s end
  def image_tag(src, _opts = {}) "<img src=\"#{src}\">" end
  def t(key, _opts = {}) "[#{key}]" end
  def money(v) "$#{v}" end
  def handleize(s) s.to_s.downcase.gsub(/[^a-z0-9]+/, '-') end
  def json(input) JSON.generate(input) end
end
Liquid::Template.register_filter(ShopifyFilters)

# Shopify theme tags the standalone gem does not know about.
class NullTag < Liquid::Block
  def render(_ctx) '' end
end
%w[schema javascript stylesheet doc].each { |t| Liquid::Template.register_tag(t, NullTag) }

class StyleTag < Liquid::Block
  def render(ctx) "<style>#{super}</style>" end
end
Liquid::Template.register_tag('style', StyleTag)

class FormTag < Liquid::Block
  def initialize(name, markup, opts) super; end
  def render(ctx) "<form>#{super}</form>" end
end
Liquid::Template.register_tag('form', FormTag)

class ThemeFs
  def read_template_file(path)
    file = File.join(THEME, 'snippets', "#{path}.liquid")
    raise Liquid::FileSystemError, "missing snippet #{path}" unless File.exist?(file)
    strip(File.read(file))
  end

  def self.strip(src) new.strip(src) end
  def strip(src) src.gsub(/\{%-?\s*doc\s*-?%\}.*?\{%-?\s*enddoc\s*-?%\}/m, '') end
end
Liquid::Template.file_system = ThemeFs.new

# Shopify's `collections` supports both iteration and lookup by handle
# (`collections['best-sellers']`), and reports `.size`. A plain array models only
# the first of those, which would hide real bugs in handle resolution.
class CollectionsLookup
  include Enumerable

  def initialize(list) = @list = list
  def each(&block) = @list.each(&block)
  def size = @list.size
  def to_liquid = self

  def key?(key)
    key.to_s == 'size' || @list.any? { |c| c['handle'].to_s == key.to_s }
  end

  def [](key)
    return @list.size if key.to_s == 'size'
    @list.find { |c| c['handle'].to_s == key.to_s }
  end
end

# --- stub data ------------------------------------------------------------
# Theme setting defaults come from settings_schema.json itself, so the stubs
# cannot drift away from the real schema as settings are added.
SCHEMA_DEFAULTS = begin
  groups = JSON.parse(File.read(File.join(THEME, 'config', 'settings_schema.json')))
  groups.flat_map { |g| g['settings'] || [] }
        .select { |st| st['id'] }
        .each_with_object({}) { |st, acc| acc[st['id']] = st['default'] }
end.freeze

def settings(overrides = {})
  SCHEMA_DEFAULTS.merge(
    'logo' => nil,
    'menu_color_scheme' => 'scheme-1',
  ).merge(overrides)
end

def shop(overrides = {})
  {
    'name' => 'Lumen Studio', 'email' => 'hello@lumen.test', 'phone' => '+1 555 0142',
    'address' => { 'summary' => '18 Kiln Road, Brooklyn NY 11222, United States',
                   'street' => '18 Kiln Road', 'city' => 'Brooklyn',
                   'province' => 'New York', 'province_code' => 'NY', 'zip' => '11222',
                   'country' => 'United States' },
    'policies' => {
      'privacy_policy' => { 'url' => '/policies/privacy-policy', 'title' => 'Privacy Policy' },
      'refund_policy' => { 'url' => '/policies/refund-policy', 'title' => 'Refund Policy' },
      'shipping_policy' => { 'url' => '/policies/shipping-policy', 'title' => 'Shipping Policy' },
      'terms_of_service' => { 'url' => '/policies/terms-of-service', 'title' => 'Terms of Service' },
    },
    'customer_accounts_enabled' => true,
  }.merge(overrides)
end

ROUTES = { 'root_url' => '/', 'all_products_collection_url' => '/collections/all', 'account_url' => '/account',
           'search_url' => '/search', 'collections_url' => '/collections' }

def base_ctx(over = {})
  {
    'settings' => settings(over.delete('settings') || {}),
    'shop' => shop(over.delete('shop') || {}),
    'routes' => ROUTES,
    'pages' => over.delete('pages') || {},
    'collections' => CollectionsLookup.new(over.delete('collections') || []),
    'request' => { 'path' => '/', 'page_type' => 'index', 'origin' => 'https://lumen.test',
                   'locale' => { 'endonym_name' => 'English' } },
    'cart' => { 'currency' => { 'iso_code' => 'USD' } },
    'section' => { 'id' => 'sec1', 'settings' => { 'menu_color_scheme' => 'scheme-1' }, 'blocks' => [] },
  }.merge(over)
end

# Shopify keeps the global drops (shop, settings, routes, collections, pages,
# request, section) visible inside a {% render %}d snippet and isolates only the
# caller's own assigns. static_environments is the liquid gem's equivalent.
def render_snippet(name, ctx)
  src = ThemeFs.strip(File.read(File.join(THEME, 'snippets', "#{name}.liquid")))
  tpl = Liquid::Template.parse(src, error_mode: :strict)
  context = Liquid::Context.build(static_environments: ctx)
  out = tpl.render!(context)
  raise tpl.errors.first if tpl.errors.any?
  out
end


$failures = 0
def check(label)
  out = yield
  puts "PASS  #{label}"
  out
rescue => e
  $failures += 1
  puts "FAIL  #{label}\n      #{e.class}: #{e.message}"
  nil
end

def expect(label, actual, matcher)
  ok = matcher.is_a?(Regexp) ? actual =~ matcher : actual.to_s.include?(matcher.to_s)
  if ok then puts "PASS  #{label}"
  else $failures += 1; puts "FAIL  #{label}\n      got: #{actual.to_s[0, 400].inspect}"
  end
end

# Renders a section with its schema defaults applied, the way the theme editor
# would on a store that has never touched the section.
def render_section(name, over = {})
  raw = File.read(File.join(THEME, 'sections', "#{name}.liquid"))
  schema = raw[/\{%\s*schema\s*%\}(.*?)\{%\s*endschema\s*%\}/m, 1]
  require 'json'
  parsed = schema ? JSON.parse(schema) : {}

  defaults = {}
  (parsed['settings'] || []).each { |st| defaults[st['id']] = st['default'] if st['id'] }
  block_defaults = {}
  (parsed['blocks'] || []).each do |b|
    d = {}
    (b['settings'] || []).each { |st| d[st['id']] = st['default'] if st['id'] }
    block_defaults[b['type']] = d
  end

  preset = (parsed['presets'] || []).first
  blocks = ((preset && preset['blocks']) || []).each_with_index.map do |b, i|
    { 'id' => "block#{i}", 'type' => b['type'],
      'settings' => (block_defaults[b['type']] || {}).merge(b['settings'] || {}),
      'shopify_attributes' => '' }
  end

  section = { 'id' => 'test-section', 'settings' => defaults.merge(over.delete('section_settings') || {}),
              'blocks' => blocks }
  section['blocks'] = over.delete('blocks') if over.key?('blocks')

  ctx = base_ctx(over).merge('section' => section)
  src = ThemeFs.strip(raw)
  tpl = Liquid::Template.parse(src, error_mode: :strict)
  out = tpl.render!(Liquid::Context.build(static_environments: ctx))
  raise tpl.errors.first if tpl.errors.any?
  out
end
