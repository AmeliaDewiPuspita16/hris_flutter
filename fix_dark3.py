#!/usr/bin/env python3
"""
fix_dark3.py -- ikon/teks hijau tua yang tidak terlihat di mode gelap.

  * AppColors.primaryMid yang dipakai sebagai warna teks/ikon/garis
      -> AppColors.primaryMidText (mode terang tetap primaryMid)
  * pasangan `color: AppColors.primary, background: AppColors.primaryLight`
    (data menu/kategori: ikon di atas tint) -> primaryText
  * nav bawah Home & ikon kartu layanan Home.

Pakai (setelah app_colors.dart terbaru ditimpa):
    python fix_dark3.py lib --dry-run   |   python fix_dark3.py lib
    python strip_const.py lib           |   flutter analyze
"""
import re, sys, pathlib, importlib.util

here = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('fd', here / 'fix_dark.py')
fd = importlib.util.module_from_spec(spec); spec.loader.exec_module(fd)
sc = fd.sc

FG_KEYS = fd.FG_KEYS | {'selectedItemColor', 'unselectedItemColor', 'selectedColor'}
PM_RE = re.compile(r'AppColors\.primaryMid(?!\w)')
PAIR_RE = re.compile(r'(color:\s*)AppColors\.primary(?!\w)(,\s*background:\s*AppColors\.primaryLight)')

SPECIAL = [
    ('home_bottom_nav.dart', 'selectedItemColor: AppColors.primary,', 'selectedItemColor: AppColors.primaryText,'),
    ('layanan_section.dart',
     'final iconColor = featured ? AppColors.primaryMid : service.color;',
     'final iconColor = featured\n        ? AppColors.primaryMidText\n        : (AppColors.isDark ? AppColors.onDark(service.color) : service.color);'),
]


# Ikon/teks/garis hijau-sedang pada file tertentu (konteksnya sudah diperiksa satu per satu)
SPECIAL_RE = [
    ('hris_menu_config.dart', r'color: AppColors\.primaryMid(,\s*background: AppColors\.primaryLight)', r'color: AppColors.primaryMidText\1'),
    ('pengajuan_repository.dart', r'color: AppColors\.primaryMid(,\s*background: AppColors\.primaryLight)', r'color: AppColors.primaryMidText\1'),
    ('app_button.dart', r'fg: AppColors\.primaryMid(?!\w)', 'fg: AppColors.primaryMidText'),
    ('app_button.dart', r'border: AppColors\.primaryMid(?!\w)', 'border: AppColors.primaryMidText'),
    ('indent_progress_status.dart', r'IndentProgressStatus\.done => AppColors\.primaryMid,', 'IndentProgressStatus.done => AppColors.primaryMidText,'),
    ('est_decision_dialog.dart', r'focusedBorder: _border\(AppColors\.primaryMid\)', 'focusedBorder: _border(AppColors.primaryMidText)'),
    ('est_progress_timeline.dart', r'color: _isDone \? AppColors\.primaryMid : AppColors\.border', 'color: _isDone ? AppColors.primaryMidText : AppColors.border'),
    ('it_request_card.dart', r'return \(AppColors\.primaryMid, AppColors\.primaryLight\);', 'return (AppColors.primaryMidText, AppColors.primaryLight);'),
]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    root = pathlib.Path(args[0] if args else 'lib')
    n_pm = n_pair = n_sp = changed = 0
    for path in sorted(root.rglob('*.dart')):
        pp = str(path).replace('\\', '/')
        if '/core/theme/' in pp: continue
        raw = path.read_bytes().decode('utf-8'); crlf = '\r\n' in raw
        s = raw.replace('\r\n', '\n'); m = sc.mask(s)
        edits = []
        for x in PM_RE.finditer(m):
            callee, key = fd.ctx(m, x.start())
            fg = key in FG_KEYS or (callee in fd.FG_CALLEES and key != 'backgroundColor') \
                 or m[x.end():x.end() + 12].startswith('.withValues')
            if fg: edits.append((x.start(), x.end(), 'AppColors.primaryMidText')); n_pm += 1
        for a, b, t in sorted(edits, key=lambda e: e[0], reverse=True):
            s = s[:a] + t + s[b:]
        s, k = PAIR_RE.subn(r'\1AppColors.primaryText\2', s); n_pair += k
        for name, pat, rep in SPECIAL_RE:
            if pp.endswith('/' + name):
                s, k = re.subn(pat, rep, s); n_sp += k
        for name, old, new in SPECIAL:
            if pp.endswith('/' + name) and old in s:
                s = s.replace(old, new); n_sp += 1
        out = s.replace('\n', '\r\n') if crlf else s
        if out != raw:
            changed += 1
            if not dry: path.write_bytes(out.encode('utf-8'))
    print(f'File diubah                      : {changed}')
    print(f'primaryMid (teks/ikon) diganti   : {n_pm}')
    print(f'pasangan color/background diganti: {n_pair}')
    print(f'perbaikan khusus                 : {n_sp}')
    if dry: print('(dry-run: tidak ada file yang ditulis)')


if __name__ == '__main__':
    main()
