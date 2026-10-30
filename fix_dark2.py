#!/usr/bin/env python3
"""
fix_dark2.py -- perbaikan lanjutan dark mode (warna label, chip, badge, tombol).

Jalankan SETELAH app_colors.dart terbaru ditimpa (ada AppColors.solid):
    python fix_dark2.py lib --dry-run
    python fix_dark2.py lib
    python strip_const.py lib     (aman dijalankan ulang)
    flutter analyze
"""
import sys, pathlib

SOLID = lambda t: f'AppColors.solid({t})'
RULES = [
    # chip status aktif: latar solid gelap (bukan pastel) + teks putih
    ('pr_status_filter_bar.dart', 'color: active ? color : AppColors.card,', 'color: active ? AppColors.solid(color) : AppColors.card,', 1),
    ('pr_status_filter_bar.dart', 'color: color.withValues(alpha: 0.25),', 'color: AppColors.solid(color).withValues(alpha: 0.25),', 1),
    ('leave_approval_screen.dart', 'color: active ? color : AppColors.card,', 'color: active ? AppColors.solid(color) : AppColors.card,', 1),
    ('leave_approval_screen.dart', 'active ? AppColors.primary : Colors.white.withValues(alpha: 0.75)', 'active ? AppColors.primaryText : Colors.white.withValues(alpha: 0.75)', 1),
    ('leave_approval_screen.dart', 'backgroundColor: feedback.isError ? AppColors.rejected : null,', 'backgroundColor: feedback.isError ? AppColors.solid(AppColors.rejected) : null,', 1),
    ('pr_detail_screen.dart', 'feedback.isError ? AppColors.rejected : AppColors.primary', 'feedback.isError ? AppColors.solid(AppColors.rejected) : AppColors.primary', 1),
    # badge angka merah (teks putih)
    ('leave_approval_screen.dart', 'color: AppColors.rejected,', 'color: AppColors.badge,', 1),
    ('hris_menu_screen.dart', 'color: AppColors.rejected,', 'color: AppColors.badge,', 1),
    ('indent_tab_bar.dart', 'color: AppColors.rejected,', 'color: AppColors.badge,', 1),
    ('est_request_tab_bar.dart', 'color: AppColors.rejected,', 'color: AppColors.badge,', 1),
    ('it_request_tab_bar.dart', 'color: AppColors.rejected,', 'color: AppColors.badge,', 1),
    # tombol / FAB solid berteks putih
    ('indent_vehicle_screen.dart', 'backgroundColor: AppColors.orange,', 'backgroundColor: AppColors.solid(AppColors.orange),', 1),
    ('hse_work_request_list_screen.dart', 'backgroundColor: AppColors.orange,', 'backgroundColor: AppColors.solid(AppColors.orange),', 1),
    ('est_request_screen.dart', 'backgroundColor: AppColors.orange,', 'backgroundColor: AppColors.solid(AppColors.orange),', 1),
    ('it_form_and_media_tab.dart', 'backgroundColor: AppColors.orange,', 'backgroundColor: AppColors.solid(AppColors.orange),', 1),
    ('indent_delete_dialog.dart', 'backgroundColor: AppColors.hseRequest,', 'backgroundColor: AppColors.solid(AppColors.hseRequest),', 1),
    ('est_delete_dialog.dart', 'backgroundColor: AppColors.hseRequest,', 'backgroundColor: AppColors.solid(AppColors.hseRequest),', 1),
    ('est_request_detail_screen.dart', 'backgroundColor: AppColors.hseRequest,', 'backgroundColor: AppColors.solid(AppColors.hseRequest),', 1),
    ('leave_decision_sheet.dart', 'final accent = _isApprove ? AppColors.primary : AppColors.rejected;', 'final accent =\n        _isApprove ? AppColors.primary : AppColors.solid(AppColors.rejected);', 1),
    ('ims_document_menu_tile.dart', 'color: AppColors.presentMid,', 'color: AppColors.solid(AppColors.presentMid),', 1),
    ('report_tab.dart', 'color: AppColors.violet,', 'color: AppColors.solid(AppColors.violet),', 1),
    # label / teks / garis hijau yang tadinya memakai `primary` (kini hijau tua)
    ('announcement.dart', '(color: AppColors.primary, background: AppColors.primaryLight)', '(color: AppColors.primaryText, background: AppColors.primaryLight)', 1),
    ('indent_driver_choice.dart', 'final color = selected ? AppColors.primary : AppColors.textMid;', 'final color = selected ? AppColors.primaryText : AppColors.textMid;', 1),
    ('notification_filter_tabs.dart', 'final color = isActive ? AppColors.primary : AppColors.textMuted;', 'final color = isActive ? AppColors.primaryText : AppColors.textMuted;', 1),
    ('change_cover_screen.dart', 'final color = done || active ? AppColors.primary : AppColors.textMuted;', 'final color = done || active ? AppColors.primaryText : AppColors.textMuted;', 1),
    ('master_document_tile.dart', "'IMS': (AppColors.primary, AppColors.primaryLight),", "'IMS': (AppColors.primaryText, AppColors.primaryLight),", 1),
    ('master_document_tile.dart', "'HR & GA': (AppColors.primaryMid, AppColors.primaryLight),", "'HR & GA': (AppColors.primaryText, AppColors.primaryLight),", 1),
    ('layanan_section.dart', 'final chevronColor = featured ? AppColors.primary : service.color;', 'final chevronColor = featured\n        ? AppColors.primary\n        : (AppColors.isDark ? AppColors.onDark(service.color) : service.color);', 1),
]
# aturan berpola (spasi/baris baru bervariasi)
import re
REGEX = [
    ('login_field.dart', r'(_focused\s*\?\s*)AppColors\.primary(?!\w)', r'\1AppColors.primaryText'),
    ('saldo_section.dart', r'(AlwaysStoppedAnimation<Color>\(\s*)AppColors\.primary(?!\w)', r'\1AppColors.primaryText'),
]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    root = pathlib.Path(args[0] if args else 'lib')
    files = {}
    for p in root.rglob('*.dart'):
        files.setdefault(p.name, []).append(p)
    texts, applied, notes = {}, 0, []

    def get(p):
        if p not in texts:
            raw = p.read_bytes().decode('utf-8')
            texts[p] = ('\r\n' in raw, raw.replace('\r\n', '\n'))
        return texts[p][1]

    def put(p, s):
        texts[p] = (texts[p][0], s)

    for name, old, new, cnt in RULES:
        paths = files.get(name)
        if not paths: notes.append(f'file tidak ditemukan: {name}'); continue
        for p in paths:
            s = get(p)
            n = s.count(old)
            if n == 0:
                if new in s: continue        # sudah diterapkan
                notes.append(f'{name}: pola tidak ketemu -> {old[:55]}'); continue
            if n != cnt:
                notes.append(f'{name}: {n}x ditemukan (diharapkan {cnt}) -> dilewati: {old[:50]}'); continue
            put(p, s.replace(old, new)); applied += 1
    for name, pat, rep in REGEX:
        for p in files.get(name, []):
            s = get(p); s2, n = re.subn(pat, rep, s)
            if n: put(p, s2); applied += n
            elif 'primaryText' not in s: notes.append(f'{name}: pola tidak ketemu')

    changed = 0
    for p, (crlf, s) in texts.items():
        orig = p.read_bytes().decode('utf-8')
        out = s.replace('\n', '\r\n') if crlf else s
        if out != orig:
            changed += 1
            if not dry: p.write_bytes(out.encode('utf-8'))
    print(f'Penggantian diterapkan : {applied}')
    print(f'File diubah            : {changed}')
    for n in notes: print('  -', n)
    if dry: print('(dry-run: tidak ada file yang ditulis)')


if __name__ == '__main__':
    main()
