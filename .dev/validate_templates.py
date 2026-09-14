import json, re, os, glob, sys

THEME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
problems = []

def schema_for(section_type):
    path = os.path.join(THEME, 'sections', section_type + '.liquid')
    if not os.path.exists(path):
        return None
    m = re.search(r'\{%\s*schema\s*%\}(.*?)\{%\s*endschema\s*%\}', open(path).read(), re.S)
    return json.loads(m.group(1)) if m else {}

def setting_ids(settings):
    return {s['id'] for s in (settings or []) if 'id' in s}

def check(doc, label):
    for key, sec in (doc.get('sections') or {}).items():
        stype = sec.get('type')
        sch = schema_for(stype)
        if sch is None:
            problems.append(f'{label}: section "{key}" has unknown type "{stype}"')
            continue
        allowed = setting_ids(sch.get('settings'))
        for sid in (sec.get('settings') or {}):
            if sid not in allowed:
                problems.append(f'{label}: section "{key}" ({stype}) sets unknown setting "{sid}"')

        block_schemas = {b['type']: b for b in (sch.get('blocks') or [])}
        for bkey, blk in (sec.get('blocks') or {}).items():
            btype = blk.get('type')
            if btype not in block_schemas:
                problems.append(f'{label}: section "{key}" ({stype}) uses unknown block type "{btype}"')
                continue
            ballowed = setting_ids(block_schemas[btype].get('settings'))
            for sid in (blk.get('settings') or {}):
                if sid not in ballowed:
                    problems.append(f'{label}: block "{bkey}" ({stype}/{btype}) sets unknown setting "{sid}"')

        order = sec.get('block_order') or []
        for b in order:
            if b not in (sec.get('blocks') or {}):
                problems.append(f'{label}: section "{key}" block_order references missing block "{b}"')
        for b in (sec.get('blocks') or {}):
            if order and b not in order:
                problems.append(f'{label}: section "{key}" block "{b}" is missing from block_order')

    for s in (doc.get('order') or []):
        if s not in (doc.get('sections') or {}):
            problems.append(f'{label}: order references missing section "{s}"')
    for s in (doc.get('sections') or {}):
        if doc.get('order') and s not in doc['order']:
            problems.append(f'{label}: section "{s}" is missing from order')

files = sorted(glob.glob(os.path.join(THEME, 'templates', '*.json'))) + \
        sorted(glob.glob(os.path.join(THEME, 'sections', '*-group.json')))
for f in files:
    doc = json.load(open(f))
    check(doc, os.path.relpath(f, THEME))

# theme settings referenced by liquid must exist in settings_schema.json
schema = json.load(open(os.path.join(THEME, 'config', 'settings_schema.json')))
known = set()
for group in schema:
    for s in (group.get('settings') or []):
        if 'id' in s:
            known.add(s['id'])

referenced = set()
for f in glob.glob(os.path.join(THEME, '**', '*.liquid'), recursive=True):
    for m in re.finditer(r'(?<![.a-z_])settings\.([a-z0-9_]+)', open(f).read()):
        referenced.add((m.group(1), os.path.relpath(f, THEME)))

# Stale references that stock Dawn 16.0.0 ships with. Listed so a genuinely
# broken reference in theme code still shows up.
DAWN_KNOWN_STALE = {
    ('color_background', 'templates/gift_card.liquid'),
    ('media_padding', 'layout/password.liquid'),
    ('media_padding', 'layout/theme.liquid'),
}

for name, f in sorted(referenced):
    if name not in known and (name, f) not in DAWN_KNOWN_STALE:
        problems.append(f'{f}: references settings.{name}, which is not declared in settings_schema.json')

# Shopify's theme importer validates section schemas and silently drops any
# section that fails, taking every template that references it down too. An
# empty string as the `default` of a text setting is one such failure, and it
# cost four build-and-import cycles to find. Catch it here instead.
EMPTY_DEFAULT_TYPES = {'text', 'textarea', 'richtext', 'inline_richtext', 'html', 'liquid', 'url', 'video_url'}

for f in sorted(glob.glob(os.path.join(THEME, 'sections', '*.liquid')) +
                glob.glob(os.path.join(THEME, 'snippets', '*.liquid')) +
                glob.glob(os.path.join(THEME, 'blocks', '*.liquid'))):
    body = open(f, encoding='utf-8').read()
    m = re.search(r'{%-?\s*schema\s*-?%}(.*?){%-?\s*endschema\s*-?%}', body, re.S)
    if not m:
        continue
    rel = os.path.relpath(f, THEME)
    try:
        parsed = json.loads(m.group(1))
    except ValueError as exc:
        problems.append(f'{rel}: schema is not valid JSON ({exc})')
        continue

    groups = [parsed.get('settings') or []]
    for block in (parsed.get('blocks') or []):
        if isinstance(block, dict):
            groups.append(block.get('settings') or [])

    for group in groups:
        for setting in group:
            if not isinstance(setting, dict):
                continue
            if 'default' not in setting:
                continue
            if setting['default'] == '' and setting.get('type') in EMPTY_DEFAULT_TYPES:
                problems.append(
                    f'{rel}: setting "{setting.get("id")}" has an empty default. '
                    'Shopify drops the whole section on import — omit the key instead.')

# store-content/ is pasted into pages by hand on every store, so a token that
# the theme does not implement would sit there as literal [[text]] on a live
# legal page. Check the two stay in step.
tokens_src = open(os.path.join(THEME, 'snippets', 'store-tokens.liquid'), encoding='utf-8').read()
implemented = set(re.findall(r"replace:\s*'\[\[([a-z0-9_]+)\]\]'", tokens_src))

for f in sorted(glob.glob(os.path.join(THEME, 'store-content', '*.html'))):
    rel = os.path.relpath(f, THEME)
    for token in sorted(set(re.findall(r'\[\[([a-z0-9_]+)\]\]', open(f, encoding='utf-8').read()))):
        if token not in implemented:
            problems.append(f'{rel}: uses [[{token}]], which store-tokens.liquid does not substitute')

print('\n'.join(problems) if problems else 'templates, block types, settings and theme settings all resolve')
sys.exit(1 if problems else 0)
