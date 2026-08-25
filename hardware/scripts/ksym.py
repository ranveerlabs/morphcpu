"""minimal KiCad s-expression reader + symbol/pin extractor.

used by gen_schematic.py. small on purpose, it only has to parse symbol
libraries well enough to find pin positions and to lift a symbol definition
verbatim into a schematic's lib_symbols block.

regex-free and backslash-free on purpose so the source survives being piped
thru shells and heredocs unharmed.
"""

BS = chr(92)
QUOTE = chr(34)


def tokenize(text):
    tokens = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c in ' \t\r\n':
            i += 1
        elif c == '(' or c == ')':
            tokens.append(c)
            i += 1
        elif c == QUOTE:
            j = i + 1
            buf = [QUOTE]
            while j < n:
                d = text[j]
                if d == BS and j + 1 < n:
                    buf.append(text[j])
                    buf.append(text[j + 1])
                    j += 2
                    continue
                buf.append(d)
                j += 1
                if d == QUOTE:
                    break
            tokens.append(''.join(buf))
            i = j
        else:
            j = i
            while j < n and text[j] not in ' \t\r\n()':
                j += 1
            tokens.append(text[i:j])
            i = j
    return tokens


def parse(text):
    stack = [[]]
    for tok in tokenize(text):
        if tok == '(':
            new = []
            stack[-1].append(new)
            stack.append(new)
        elif tok == ')':
            if len(stack) > 1:
                stack.pop()
        else:
            stack[-1].append(tok)
    return stack[0]


def unquote(s):
    if not isinstance(s, str) or len(s) < 2:
        return s
    if s[0] != QUOTE or s[-1] != QUOTE:
        return s
    body = s[1:-1]
    out = []
    i = 0
    while i < len(body):
        if body[i] == BS and i + 1 < len(body):
            out.append(body[i + 1])
            i += 2
        else:
            out.append(body[i])
            i += 1
    return ''.join(out)


def find_all(node, name):
    return [x for x in node if isinstance(x, list) and x and x[0] == name]


def find_one(node, name):
    got = find_all(node, name)
    return got[0] if got else None


def load_lib(path):
    with open(path, 'r', encoding='utf-8') as f:
        tree = parse(f.read())
    root = tree[0]
    return {unquote(s[1]): s for s in find_all(root, 'symbol')}


def symbol_source(path, name):
    """Raw text of one top-level (symbol "name" ...) block, for lib_symbols."""
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    needle = '\t(symbol ' + QUOTE + name + QUOTE + '\n'
    start = text.find(needle)
    if start < 0:
        raise KeyError('symbol ' + name + ' not in ' + path)
    i = start
    depth = 0
    in_str = False
    skip = False
    while i < len(text):
        c = text[i]
        if skip:
            skip = False
        elif in_str:
            if c == BS:
                skip = True
            elif c == QUOTE:
                in_str = False
        else:
            if c == QUOTE:
                in_str = True
            elif c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0:
                    return text[start:i + 1]
        i += 1
    raise ValueError('unterminated symbol ' + name)


def _unit_of(subname):
    parts = subname.split('_')
    if len(parts) >= 3 and parts[-1].isdigit() and parts[-2].isdigit():
        return int(parts[-2])
    return 1


def pins_of(sym):
    """Every pin in a symbol, across its per-unit sub-symbols."""
    result = []
    for sub in find_all(sym, 'symbol'):
        unit = _unit_of(unquote(sub[1]))
        for pin in find_all(sub, 'pin'):
            at = find_one(pin, 'at')
            length = find_one(pin, 'length')
            number = find_one(pin, 'number')
            pname = find_one(pin, 'name')
            result.append({
                'unit': unit,
                'etype': pin[1],
                'x': float(at[1]),
                'y': float(at[2]),
                'angle': float(at[3]) if len(at) > 3 else 0.0,
                'length': float(length[1]) if length else 2.54,
                'number': unquote(number[1]) if number else '?',
                'name': unquote(pname[1]) if pname else '~',
            })
    return result


def dump(node, indent=0):
    """Re-serialise a parsed tree. KiCad only cares about structure, not
    whitespace, so this keeps atoms that follow the head on the head line and
    puts each nested list on its own indented line."""
    pad = chr(9) * indent
    if not isinstance(node, list):
        return pad + str(node)
    if not node:
        return pad + '()'
    lead = []
    i = 0
    while i < len(node) and not isinstance(node[i], list):
        lead.append(str(node[i]))
        i += 1
    if i == len(node):
        return pad + '(' + ' '.join(lead) + ')'
    out = [pad + '(' + ' '.join(lead)]
    for child in node[i:]:
        out.append(dump(child, indent + 1))
    out.append(pad + ')')
    return chr(10).join(out)
