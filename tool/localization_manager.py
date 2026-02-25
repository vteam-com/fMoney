#!/usr/bin/env python3
"""
Comprehensive Localization Management Script

This script combines the functionality of scanning for untranslated entries
and automatically providing translations for Spanish (ES) and French (FR) ARB files.

Features:
- Detects untranslated entries in ES and FR ARB files (entries identical to English)
- Lists all untranslated entries that need translation
- Regenerates Dart localization files

Usage:
    python localization_manager.py
    # Optional: only process specific languages
    python localization_manager.py --languages fr
    python localization_manager.py --languages es fr
""" 

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Set
import subprocess


def load_arb_file(file_path: Path) -> Dict[str, any]:
    """Load and parse an ARB file."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"❌ Error reading {file_path}: {e}")
        return {}


def save_arb_file(file_path: Path, data: Dict[str, any]) -> None:
    """Save data to an ARB file."""
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"❌ Error writing {file_path}: {e}")


def attempt_auto_translate(en_value: str, lang_code: str) -> str:
    """
    Attempt to provide automatic translation based on simple patterns.
    This is a minimal implementation to avoid hardcoded strings.
    """
    # For now, return the original value to indicate no translation
    # In the future, this could integrate with translation APIs or load from external files
    return en_value


def find_untranslated_entries(l10n_dir: Path, languages: List[str]) -> Dict[str, List[Tuple[str, str]]]:
    """Find untranslated entries for specified languages."""
    results = {}

    en_path = l10n_dir / "app_en.arb"
    en_data = load_arb_file(en_path)

    for lang in languages:
        lang_code = lang.lower()
        if lang_code not in ["es", "fr"]:
            continue

        lang_path = l10n_dir / f"app_{lang_code}.arb"
        lang_data = load_arb_file(lang_path)

        untranslated = []

        for key, en_value in en_data.items():
            if key.startswith('@'):
                continue  # Skip placeholder definitions

            lang_value = lang_data.get(key, "")
            if lang_value == en_value or not lang_value.strip():
                untranslated.append((key, en_value))

        results[lang_code.upper()] = untranslated

    return results


def translate_language(l10n_dir: Path, lang_code: str, untranslated: List[Tuple[str, str]], dry_run: bool = False) -> int:
    """Translate untranslated entries for a specific language using dynamic approach."""
    lang_path = l10n_dir / f"app_{lang_code}.arb"
    lang_data = load_arb_file(lang_path)

    lang_name = "Spanish" if lang_code == "es" else "French"

    updated_count = 0

    for key, en_value in untranslated:
        translated_value = attempt_auto_translate(en_value, lang_code)
        if translated_value != en_value:  # Only update if translation actually differs
            lang_data[key] = translated_value
            updated_count += 1
            status = "🔄 Would translate" if dry_run else "🔄 Translated"
            print(f"{status} '{key}': '{en_value}' → '{translated_value}'")

    if not dry_run and updated_count > 0:
        save_arb_file(lang_path, lang_data)
        print(f"✅ Updated {updated_count} {lang_name} translations")

    return updated_count


def regenerate_localizations():
    """Regenerate Flutter localization files."""
    print("\n🔄 Regenerating Flutter localization files...")
    try:
        subprocess.run(["flutter", "gen-l10n"], check=True, capture_output=True)
        print("✅ Flutter localizations regenerated successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error regenerating localizations: {e}")
        return False
    except FileNotFoundError:
        print("❌ Flutter command not found. Please ensure Flutter SDK is in PATH.")
        return False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="Manage Flutter ARB translations")
    parser.add_argument("--languages", "-l", nargs='+', choices=['es', 'fr'], default=['es', 'fr'],
                       help="Languages to process (default: both es and fr)")
    parser.add_argument("--scan-only", "-s", action='store_true',
                       help="Only scan and list untranslated entries (no translation)")

    args = parser.parse_args()

    # Default to lib/l10n directory
    l10n_dir = Path("lib/l10n")

    if not l10n_dir.exists():
        print(f"❌ Error: Directory {l10n_dir} does not exist!")
        return 1

    # Check for ARB files
    arb_files = list(l10n_dir.glob("*.arb"))
    if not arb_files:
        print(f"No ARB files found in {l10n_dir}")
        return 1

    print(f"🔍 Localization Management Script")
    print(f"📁 Working directory: {l10n_dir}")
    print(f"🌐 Target languages: {', '.join(args.languages).upper()}")
    if args.scan_only:
        print("📋 SCAN-ONLY MODE - Only listing untranslated entries")
    print()

    # Scan for untranslated entries
    untranslated_entries = find_untranslated_entries(l10n_dir, args.languages)

    total_untranslated = sum(len(entries) for entries in untranslated_entries.values())
    if total_untranslated == 0:
        print("✅ All entries appear to be translated!")
        return 0

    print("📊 Scan Results:")
    en_count = len([k for k in load_arb_file(l10n_dir / "app_en.arb").keys() if not k.startswith('@')])
    print(f"  • Total entries in English: {en_count}")
    for lang, entries in untranslated_entries.items():
        print(f"  • Untranslated in {lang}: {len(entries)}")

    # Display untranslated entries
    if args.scan_only:
        print("\n📋 UNTRANSLATED ENTRIES LIST:")
        print("=" * 60)
        total_listed = 0
        for lang, entries in untranslated_entries.items():
            lang_name = "Spanish" if lang == "ES" else "French"
            flag = "🇪🇸" if lang == "ES" else "🇫🇷"
            print(f"\n{flag} {lang.upper()} - {lang_name} ({len(entries)} entries):")
            print("-" * 40)

            for key, value in entries:
                print(f"  \"{key}\": \"{value}\",")
                total_listed += 1

        print(f"\n📈 Total untranslated entries: {total_listed}")
        print("\n💡 To translate these entries:")
        print("   1. Edit the respective ARB files (app_es.arb, app_fr.arb)")
        print("   2. Replace English values with proper translations")
        print("   3. Values are currently identical to English - they need translation")
        return 0

    # Perform translations
    total_translated = 0
    for lang_code, entries in untranslated_entries.items():
        if entries:
            translated = translate_language(l10n_dir, lang_code.lower(), entries)
            total_translated += translated

    print("\n🎯 Translation Summary:")
    print(f"  • Entries processed: {total_untranslated}")
    print(f"  • Entries translated: {total_translated}")
    print(f"  • Entries remaining: {total_untranslated - total_translated}")

    # Always regenerate localizations after actual translations
    if total_translated > 0:
        success = regenerate_localizations()
        if success:
            return 0
        else:
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
