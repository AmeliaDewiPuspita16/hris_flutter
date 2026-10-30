#!/usr/bin/env python3
"""
fix_dark.py -- langkah 3 migrasi dark mode (jalankan SETELAH app_colors.dart baru
ditimpa, lalu jalankan strip_const.py sekali lagi).

  1. Permukaan putih (Colors.white di BoxDecoration/Material/InputDecoration/
     backgroundColor/dropdownColor ...) -> AppColors.card.
  2. AppColors.primary yang dipakai sebagai warna teks/ikon/garis ->
     AppColors.primaryText (latar & tombol tetap AppColors.primary).
  3. Beberapa perbaikan khusus (header ber-SVG terang, warna pastel jenis cuti,
     overlay cover profil, dst.).

Pakai:  python fix_dark.py lib --dry-run   |   python fix_dark.py lib
Lalu :  python strip_const.py lib   &&   flutter analyze
"""
import re, sys, pathlib, importlib.util

here = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('sc', here / 'strip_const.py')
sc = importlib.util.module_from_spec(spec); spec.loader.exec_module(sc)


def ctx(m, pos):
    """(nama pemanggil, key argumen) untuk ekspresi di posisi pos."""
    depth = 0; i = pos - 1; seg_start = None
    while i >= 0:
        c = m[i]
        if c in ')]}': depth += 1
        elif c in '([{':
            if depth == 0: break
            depth -= 1
        elif c == ',' and depth == 0 and seg_start is None:
            seg_start = i + 1
        i -= 1
    callee = ''
    if i >= 0 and m[i] == '(':
        mm = re.search(r'([A-Za-z_][\w.]*)\s*$', m[:i])
        callee = mm.group(1) if mm else ''
    start = seg_start if seg_start is not None else i + 1
    k = re.match(r'\s*([A-Za-z_]\w*)\s*:', m[start:pos])
    key = k.group(1) if k else ''
    callee = callee.split('.')[-1]
    if callee in ('WidgetStatePropertyAll', 'MaterialStatePropertyAll') and i >= 0:
        # key sebenarnya ada di luar: foregroundColor: WidgetStatePropertyAll(...)
        mm = re.search(r'([A-Za-z_]\w*)\s*:\s*[\w.]*\s*$', m[:i])
        key = mm.group(1) if mm else key
    return callee, key


SURF = {'BoxDecoration', 'Container', 'Material', 'ColoredBox', 'DecoratedBox', 'Scaffold',
        'AppBar', 'InputDecoration', 'ChoiceChip', 'FilterChip', 'Card', 'Chip', 'Ink'}
WHITE_KEYS = {'color', 'backgroundColor', 'fillColor', 'dropdownColor', 'disabledBackgroundColor'}
NOT_SURF = {'Icon', 'TextStyle', 'copyWith', 'CircularProgressIndicator'}
FG_CALLEES = {'Icon', 'TextStyle', 'Text', 'copyWith', 'CircularProgressIndicator',
              'RefreshIndicator', 'BorderSide', 'all', 'TextField', 'Checkbox', 'Radio',
              'Switch', 'LinearProgressIndicator'}
FG_KEYS = {'foregroundColor', 'iconColor', 'cursorColor', 'activeColor', 'indicatorColor',
           'labelColor', 'textColor', 'selectionHandleColor'}

WHITE_RE = re.compile(r'Colors\.white(?!\w|\.with|\d)')
PRIMARY_RE = re.compile(r'AppColors\.primary(?!\w)')


def sub_once(s, pattern, repl, label, report, flags=0):
    new, n = re.subn(pattern, repl, s, flags=flags)
    if n == 0: report.append(f"  - tidak ketemu: {label}")
    return new, n


def special(path, s, report):
    """Perbaikan khusus per file. Pola dibuat toleran terhadap spasi/CRLF."""
    p = str(path).replace('\\', '/')
    n = 0
    if p.endswith('portal_category_page.dart'):
        s, k = re.subn(r"SvgPicture\.asset\(\s*'assets/icons/header-background\.svg',\s*fit:\s*BoxFit\.cover\s*\)",
                       "AppColors.isDark\n              ? DecoratedBox(decoration: BoxDecoration(gradient: AppColors.pageGradient))\n              : SvgPicture.asset('assets/icons/header-background.svg', fit: BoxFit.cover)", s)
        n += k
        s, k = re.subn(r'Color\(0x00F1F0EA\)', 'AppColors.bg.withValues(alpha: 0)', s); n += k
    elif p.endswith('hris_menu/presentation/screens/hris_menu_screen.dart'):
        s, k = re.subn(r'\(AppColors\.primaryLight,\s*AppColors\.primary(?=[,)])',
                       '(AppColors.primaryLight, AppColors.primaryText', s); n += k
    elif p.endswith('pengajuan/domain/leave_type.dart'):
        if '_lightColor' not in s:
            s, k = re.subn(r'Color get color \{',
                           'Color get color =>\n      AppColors.isDark ? AppColors.onDark(_lightColor) : _lightColor;\n\n  Color get _lightColor {', s); n += k
            s, k = re.subn(r'Color get background \{',
                           'Color get background =>\n      AppColors.isDark ? AppColors.tintOnCard(_lightColor) : _lightBackground;\n\n  Color get _lightBackground {', s); n += k
            if 'core/theme/app_colors.dart' not in s:
                s = re.sub(r"(import 'package:flutter/material\.dart';\r?\n)",
                           r"\1import '../../../core/theme/app_colors.dart';\n", s, count=1); n += 1
    elif p.endswith('profil/presentation/screens/profil_screen.dart'):
        for hx, a in (('F2', '0.95'), ('B3', '0.70'), ('26', '0.15')):
            s, k = re.subn(r'Color\(0x%s0E4A34\)' % hx, f'AppColors.primary.withValues(alpha: {a})', s); n += k
    elif p.endswith('pengajuan/presentation/widgets/ajukan_tab.dart'):
        s, k = re.subn(r'const Color\(0xFFFFFBEB\)', 'AppColors.isDark ? AppColors.accentBg : const Color(0xFFFFFBEB)', s); n += k
        s, k = re.subn(r'Color\(0xFF744210\)', 'AppColors.isDark ? AppColors.accentLight : const Color(0xFF744210)', s); n += k
    elif p.endswith('pengajuan/presentation/widgets/upload_field.dart') or p.endswith('core/widgets/app_attachment_field.dart'):
        s, k = re.subn(r'const Color\(0xFFFAFAFA\)', 'AppColors.isDark ? AppColors.neutralBg : const Color(0xFFFAFAFA)', s); n += k
    elif p.endswith('procurement/presentation/widgets/pr_approval_action_bar.dart'):
        s, k = re.subn(r'static const _amberText = Color\(0xFF8F6F1E\);',
                       'static const _amberText = AppColors.isDark ? AppColors.accentLight : Color(0xFF8F6F1E);', s); n += k
        s, k = re.subn(r'static const _disabledBorder = Color\(0xFFD9D8D2\);',
                       'static const _disabledBorder = AppColors.isDark ? AppColors.border : Color(0xFFD9D8D2);', s); n += k
    return s, n


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    root = pathlib.Path(args[0] if args else 'lib')
    tw = tp = ts = 0; files_changed = 0; unknown = []; notes = []
    for path in sorted(root.rglob('*.dart')):
        pp = str(path).replace('\\', '/')
        if '/core/theme/' in pp: continue
        s = path.read_bytes().decode('utf-8'); m = sc.mask(s)
        edits = []
        for x in WHITE_RE.finditer(m):
            callee, key = ctx(m, x.start())
            if key in WHITE_KEYS and callee not in NOT_SURF and \
               (callee in SURF or key in ('backgroundColor', 'fillColor', 'dropdownColor', 'disabledBackgroundColor')):
                edits.append((x.start(), x.end(), 'AppColors.card')); tw += 1
        for x in PRIMARY_RE.finditer(m):
            callee, key = ctx(m, x.start())
            tail = m[x.end():x.end() + 12]
            fg = (key in FG_KEYS) or (callee in FG_CALLEES and key != 'backgroundColor') \
                 or tail.startswith('.withValues')
            if fg:
                edits.append((x.start(), x.end(), 'AppColors.primaryText')); tp += 1
            elif not key and callee not in ('', 'fromSeed'):
                unknown.append(f"{path}:{s.count(chr(10), 0, x.start()) + 1} ({callee})")
        out = s
        for a, b, t in sorted(edits, key=lambda e: e[0], reverse=True):
            out = out[:a] + t + out[b:]
        out, k = special(path, out, notes); ts += k
        if out != s:
            files_changed += 1
            if not dry: path.write_bytes(out.encode('utf-8'))
    print(f"File diubah                           : {files_changed}")
    print(f"Colors.white (permukaan) -> card       : {tw}")
    print(f"primary (teks/ikon/garis) -> primaryText: {tp}")
    print(f"Perbaikan khusus                       : {ts}")
    if notes: print('Catatan:'); [print(n) for n in notes]
    if unknown: print(f"primary yang tidak bisa diklasifikasi ({len(unknown)}), cek visual bila ada yang janggal:"); [print('  -', u) for u in unknown[:12]]
    if dry: print('(dry-run: tidak ada file yang ditulis)')


if __name__ == '__main__':
    main()
