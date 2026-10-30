#!/usr/bin/env python3
"""
strip_const.py -- langkah 2 migrasi dark mode.

Setelah AppColors berubah dari `static const` menjadi getter, semua `const`
yang memuat AppColors tidak valid lagi. Skrip ini:

  1. Menghapus keyword `const` pada ekspresi yang memuat AppColors (atau
     anggota statis yang ikut "tercemar", mis. AppTextStyles.h2).
  2. Mengubah deklarasi `static const x = ...AppColors...;` menjadi getter
     `static Tipe get x => ...;` (BUKAN `final`, supaya nilainya ikut berganti
     saat mode berubah).
  3. Melaporkan kasus yang harus dibereskan manual (nilai default parameter).

Pakai:   python strip_const.py lib --dry-run     (lihat ringkasan saja)
         python strip_const.py lib               (terapkan; commit git dulu)
Lalu jalankan `flutter analyze`.
"""
import re, sys, pathlib
from collections import defaultdict


def mask(s):
    """Salinan s dengan komentar & isi string diganti spasi (panjang sama)."""
    n = len(s); out = list(s)

    def blank(a, b):
        for k in range(a, b):
            if out[k] not in '\r\n':
                out[k] = ' '

    def skip_interp(j):
        depth = 1
        while j < n and depth:
            c = s[j]
            if c in '\'"':
                j = skip_string(j); continue
            if c == '{': depth += 1
            elif c == '}': depth -= 1
            j += 1
        return j

    def skip_string(i):
        j = i; raw = False
        if s[j] == 'r' and j + 1 < n and s[j + 1] in '\'"':
            raw = True; j += 1
        q = s[j]; triple = s.startswith(q * 3, j)
        j += 3 if triple else 1
        while j < n:
            c = s[j]
            if not raw and c == '\\':
                j += 2; continue
            if not raw and c == '$' and j + 1 < n and s[j + 1] == '{':
                j = skip_interp(j + 2); continue
            if triple:
                if s.startswith(q * 3, j): return j + 3
            else:
                if c == q: return j + 1
                if c == '\n': return j
            j += 1
        return n

    i = 0
    while i < n:
        c = s[i]
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            j = s.find('\n', i); j = n if j < 0 else j
            blank(i, j); i = j; continue
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            j = s.find('*/', i + 2); j = n if j < 0 else j + 2
            blank(i, j); i = j; continue
        if c in '\'"' or (c == 'r' and i + 1 < n and s[i + 1] in '\'"'
                          and (i == 0 or not (s[i - 1].isalnum() or s[i - 1] == '_'))):
            j = skip_string(i); blank(i, j); i = j; continue
        i += 1
    return ''.join(out)


def match(m, i):
    depth = 0
    for j in range(i, len(m)):
        c = m[j]
        if c in '([{': depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0: return j
    return -1


def stmt_end(m, i):
    depth = 0
    for j in range(i, len(m)):
        c = m[j]
        if c in '([{': depth += 1
        elif c in ')]}': depth -= 1
        elif c == ';' and depth == 0: return j
    return -1


# Tipe untuk deklarasi yang tidak bisa ditebak otomatis (record/list/map).
MANUAL_TYPES = {
    ('home/domain/announcement.dart', '_palette'):
        'List<({Color color, Color background})>',
    ('ims_document/shared/presentation/widgets/master_document_tile.dart', '_palette'):
        'Map<String, (Color, Color)>',
}

CLASS_RE = re.compile(r'\b(?:class|mixin|extension|enum)\s+(\w+)')
DECL_RE = re.compile(
    r'(?m)^([ \t]*)((?:static[ \t]+)?)const[ \t]+'
    r'(?:([A-Za-z_][\w<>?,. ]*?)[ \t]+)?([A-Za-z_]\w*)[ \t]*=(?!=)')
CONST_RE = re.compile(r'\bconst\b')


def class_at(classes, pos):
    name = None
    for p, nme in classes:
        if p < pos: name = nme
        else: break
    return name


def infer_type(rhs):
    rhs = rhs.strip()
    if re.fullmatch(r'AppColors\.\w+', rhs): return 'Color'
    if re.match(r'AppColors\.\w+\.\w+\(', rhs): return 'Color'
    mm = re.match(r'(?:const\s+)?([A-Z]\w*)\s*[(.]', rhs)
    if mm:
        t = mm.group(1)
        if t == 'AppColors': return 'Color'
        return t
    return None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    root = pathlib.Path(args[0] if args else 'lib')
    files = sorted(p for p in root.rglob('*.dart'))
    src, msk, classes, decls = {}, {}, {}, []
    for p in files:
        s = p.read_bytes().decode('utf-8')
        m = mask(s)
        src[p], msk[p] = s, m
        classes[p] = [(x.start(), x.group(1)) for x in CLASS_RE.finditer(m)]
        for d in DECL_RE.finditer(m):
            e = stmt_end(m, d.end())
            if e < 0: continue
            decls.append(dict(p=p, a=d.start() + len(d.group(1)), hdr_end=d.end(),
                              end=e, static=bool(d.group(2).strip()), indent=d.group(1),
                              type=(d.group(3) or '').strip(), name=d.group(4),
                              cls=class_at(classes[p], d.start()), tainted=False))

    tq, tb = set(), defaultdict(set)

    def taint_re(p):
        parts = [r'AppColors\.\w+']
        if tq: parts.append(r'\b(?:' + '|'.join(map(re.escape, sorted(tq))) + r')\b')
        if tb[p]: parts.append(r'(?<![\w.])(?:' + '|'.join(map(re.escape, sorted(tb[p]))) + r')\b')
        return re.compile('|'.join(parts))

    changed = True
    while changed:
        changed = False
        for d in decls:
            if d['tainted']: continue
            if taint_re(d['p']).search(msk[d['p']][d['hdr_end']:d['end']]):
                d['tainted'] = True; changed = True
                tb[d['p']].add(d['name'])
                if d['static'] and d['cls']: tq.add(f"{d['cls']}.{d['name']}")

    manual, total_removed, total_getters, changed_files = [], 0, 0, 0
    for p in files:
        s, m = src[p], msk[p]
        tre = taint_re(p)
        edits = []; handled = set(); tainted_ranges = []
        for d in (x for x in decls if x['p'] == p and x['tainted']):
            ln = s.count('\n', 0, d['a']) + 1
            tainted_ranges.append((d['a'], d['end']))
            handled.add(d['a'] + len(d['hdr_prefix']) if False else None)
            top_or_static = d['static'] or d['indent'] == ''
            if top_or_static:
                t = d['type'] or infer_type(s[d['hdr_end']:d['end']])
                for (suffix, nm), forced in MANUAL_TYPES.items():
                    if str(p).replace('\\', '/').endswith(suffix) and d['name'] == nm:
                        t = forced
                if not t:
                    manual.append(f"{p}:{ln}: tipe tidak bisa ditebak untuk '{d['name']}' -- ubah manual jadi getter")
                    continue
                pre = ('static ' if d['static'] else '')
                edits.append((d['a'], d['hdr_end'], f"{pre}{t} get {d['name']} =>"))
                total_getters += 1
            else:  # const lokal di dalam fungsi
                edits.append((d['a'], d['a'] + len(re.match(r'(?:static[ \t]+)?const', s[d['a']:]).group(0)),
                              'final'))
        decl_starts = {d['a'] for d in decls if d['p'] == p}
        for c in CONST_RE.finditer(m):
            pos = c.start()
            # keyword const milik deklarasi (sudah ditangani di atas / tidak tercemar)
            if any(a <= pos < b and a == pos or (a <= pos < a + 20 and pos >= a and m[a:pos].strip() in ('', 'static'))
                   for a, b in [(da, da + 1) for da in decl_starts]):
                continue
            j = c.end()
            mm = re.compile(r'[^()\[\]{}=;]*').match(m, j)
            k = mm.end()
            if k >= len(m) or m[k] in '=;': continue
            opener = k
            close = match(m, opener)
            if close < 0: continue
            seg = m[j:k].strip()
            base = re.split(r'[.<]', seg)[0] if seg else ''
            ls = m.rfind('\n', 0, pos) + 1
            before = m[ls:pos].strip()
            if base and base == class_at(classes[p], pos) and before in ('', 'factory'):
                after = m[close + 1:].lstrip()
                if after[:1] in (';', '{', ':') or after.startswith('=>'):
                    continue  # deklarasi constructor const
            if tre.search(m[j:close + 1]):
                end_rm = c.end()
                while end_rm < len(m) and m[end_rm] in ' \t':
                    end_rm += 1
                edits.append((pos, end_rm, ''))
                total_removed += 1
        # laporan default parameter yang memakai warna
        for x in re.finditer(r'(?:this\.\w+|[A-Z]\w*\??[ \t]+\w+)[ \t]*=[ \t]*(?:' + tre.pattern + ')', m):
            ln = s.count('\n', 0, x.start()) + 1
            seg = m[max(0, x.start() - 3):x.start()]
            if re.search(r'[({,]\s*$', m[max(0, x.start() - 40):x.start()]):
                manual.append(f"{p}:{ln}: nilai default parameter memakai warna -- jadikan nullable (`Color? x`) dan pakai `x ?? AppColors.y` di build()")
        if not edits: continue
        edits.sort(key=lambda e: e[0], reverse=True)
        out = s
        for a, b, t in edits:
            out = out[:a] + t + out[b:]
        changed_files += 1
        if not dry:
            p.write_bytes(out.encode('utf-8'))

    print(f"File diubah           : {changed_files}")
    print(f"`const` dihapus       : {total_removed}")
    print(f"Deklarasi -> getter   : {total_getters}")
    print(f"Perlu dicek manual    : {len(manual)}")
    for x in manual: print('  -', x)
    if dry: print('(dry-run: tidak ada file yang ditulis)')


if __name__ == '__main__':
    main()
