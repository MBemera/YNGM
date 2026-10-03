"""Embed YNGM's icon and version information using Windows resource APIs."""
import ctypes
import struct
from ctypes import wintypes
from pathlib import Path

KERNEL32 = ctypes.WinDLL("kernel32", use_last_error=True)
KERNEL32.LoadLibraryExW.argtypes = [wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD]
KERNEL32.LoadLibraryExW.restype = wintypes.HMODULE
KERNEL32.FreeLibrary.argtypes = [wintypes.HMODULE]
KERNEL32.BeginUpdateResourceW.argtypes = [wintypes.LPCWSTR, wintypes.BOOL]
KERNEL32.BeginUpdateResourceW.restype = wintypes.HANDLE
KERNEL32.UpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.LPCWSTR, wintypes.LPCWSTR,
                                    wintypes.WORD, ctypes.c_void_p, wintypes.DWORD]
KERNEL32.EndUpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.BOOL]
NAME_CALLBACK = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMODULE, ctypes.c_void_p,
                                   ctypes.c_void_p, wintypes.LPARAM)
LANG_CALLBACK = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMODULE, ctypes.c_void_p,
                                   ctypes.c_void_p, wintypes.WORD, wintypes.LPARAM)
KERNEL32.EnumResourceNamesW.argtypes = [wintypes.HMODULE, wintypes.LPCWSTR, NAME_CALLBACK, wintypes.LPARAM]
KERNEL32.EnumResourceLanguagesW.argtypes = [wintypes.HMODULE, wintypes.LPCWSTR, wintypes.LPCWSTR,
                                          LANG_CALLBACK, wintypes.LPARAM]

def resource_name(value: int | str):
    if isinstance(value, str):
        return ctypes.c_wchar_p(value)
    return ctypes.cast(ctypes.c_void_p(value), wintypes.LPCWSTR)

def list_resource_names(module: int, resource_type: int) -> list[int | str]:
    names = []
    def receive_name(module, kind, name, parameter):
        names.append(name if name <= 65535 else ctypes.wstring_at(name))
        return True
    if not KERNEL32.EnumResourceNamesW(module, resource_name(resource_type), NAME_CALLBACK(receive_name), 0):
        if ctypes.get_last_error() not in (1813, 1814):
            raise ctypes.WinError(ctypes.get_last_error())
    return names

def list_resource_languages(module: int, resource_type: int, name: int | str) -> list[int]:
    languages = []
    def receive_language(module, kind, name, language, parameter):
        languages.append(language)
        return True
    if not KERNEL32.EnumResourceLanguagesW(module, resource_name(resource_type), resource_name(name),
                                         LANG_CALLBACK(receive_language), 0):
        raise ctypes.WinError(ctypes.get_last_error())
    return languages

def find_resource_entries(executable: Path, resource_type: int) -> list[tuple[int | str, int]]:
    module = KERNEL32.LoadLibraryExW(str(executable), None, 0x22)
    if not module:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return [(name, language) for name in list_resource_names(module, resource_type)
                for language in list_resource_languages(module, resource_type, name)]
    finally:
        KERNEL32.FreeLibrary(module)

def read_icon_resources(icon_path: Path) -> tuple[bytes, list[bytes]]:
    data = icon_path.read_bytes()
    reserved, kind, count = struct.unpack_from("<HHH", data)
    if reserved != 0 or kind != 1 or count == 0:
        raise ValueError("Invalid Windows icon")
    group, images = bytearray(struct.pack("<HHH", 0, 1, count)), []
    for index in range(count):
        width, height, colors, unused, planes, bits, size, offset = struct.unpack_from("<BBBBHHII", data, 6 + 16 * index)
        if offset + size > len(data):
            raise ValueError("Truncated Windows icon")
        images.append(data[offset:offset + size])
        group.extend(struct.pack("<BBBBHHIH", width, height, colors, unused, planes, bits, size, 200 + index))
    return bytes(group), images

def pad_resource(data: bytes) -> bytes:
    return data + b"\0" * (-len(data) % 4)

def build_version_block(key: str, value: bytes = b"", children: bytes = b"", text: bool = True) -> bytes:
    header = pad_resource(struct.pack("<HHH", 0, len(value) // 2 if text else len(value), int(text))
                          + (key + "\0").encode("utf-16le"))
    result = header + pad_resource(value) + children
    return struct.pack("<H", len(result)) + result[2:]

def build_version_resource(version: str, product_name: str) -> bytes:
    major, minor, patch = (int(part) for part in version.split("."))
    version_high, version_low = major << 16 | minor, patch << 16
    fixed = struct.pack("<13I", 0xFEEF04BD, 0x10000, version_high, version_low,
                        version_high, version_low, 0x3F, 0, 0x40004, 1, 0, 0, 0)
    values = {"CompanyName": "YNGM", "FileDescription": product_name, "FileVersion": version,
              "InternalName": "YNGM", "OriginalFilename": "YNGM.exe",
              "ProductName": product_name, "ProductVersion": version}
    strings = b"".join(build_version_block(key, (value + "\0").encode("utf-16le"))
                       for key, value in values.items())
    table = build_version_block("040904B0", children=strings)
    string_info = build_version_block("StringFileInfo", children=table)
    translation = build_version_block("Translation", struct.pack("<HH", 1033, 1200), text=False)
    variable_info = build_version_block("VarFileInfo", children=translation)
    return build_version_block("VS_VERSION_INFO", fixed, string_info + variable_info, False)

def update_resource(handle: int, kind: int, name: int | str, language: int, data: bytes) -> None:
    buffer = ctypes.create_string_buffer(data)
    if not KERNEL32.UpdateResourceW(handle, resource_name(kind), resource_name(name), language,
                                   ctypes.byref(buffer), len(data)):
        raise ctypes.WinError(ctypes.get_last_error())

def embed_windows_resources(executable: Path, icon_path: Path, version: str, product_name: str) -> None:
    group, images = read_icon_resources(icon_path)
    groups = find_resource_entries(executable, 14) or [(1, 1033)]
    versions = find_resource_entries(executable, 16) or [(1, 1033)]
    version_data = build_version_resource(version, product_name)
    handle = KERNEL32.BeginUpdateResourceW(str(executable), False)
    if not handle:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        for language in {language for _, language in groups}:
            for index, image in enumerate(images):
                update_resource(handle, 3, 200 + index, language, image)
        for name, language in groups:
            update_resource(handle, 14, name, language, group)
        for name, language in versions:
            update_resource(handle, 16, name, language, version_data)
    except BaseException:
        KERNEL32.EndUpdateResourceW(handle, True)
        raise
    if not KERNEL32.EndUpdateResourceW(handle, False):
        raise ctypes.WinError(ctypes.get_last_error())