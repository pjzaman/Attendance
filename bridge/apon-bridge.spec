# -*- mode: python ; coding: utf-8 -*-
#
# PyInstaller spec for the Apon Attendance bridge.
# Build with:  pyinstaller apon-bridge.spec --clean
# Output:      dist/apon-bridge.exe (single file, no Python required
#              on the target machine).

block_cipher = None

a = Analysis(
    ['run.py'],
    pathex=[],
    binaries=[],
    datas=[],
    # firebase-admin / google-cloud-firestore use lazy imports that
    # PyInstaller's static analysis sometimes misses. Listing them
    # explicitly here avoids "module not found" errors at runtime.
    hiddenimports=[
        'firebase_admin',
        'firebase_admin.credentials',
        'firebase_admin.firestore',
        'google.cloud.firestore',
        'google.cloud.firestore_v1',
        'google.cloud.firestore_v1.services.firestore.transports.grpc',
        'google.cloud.firestore_v1.watch',
        'grpc',
        'grpc._cython.cygrpc',
        'zk',
        'zk.base',
        'zk.exception',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='apon-bridge',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
