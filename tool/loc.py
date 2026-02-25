#!/usr/bin/env python3
"""
Script to sort Flutter ARB (Application Resource Bundle) files alphabetically.

This script sorts translation keys alphabetically while preserving the correct
ordering of placeholder definitions (@keys) which must come immediately after
their corresponding translation keys.

Usage:
    python sort_arb_files.py
    # or
    python sort_arb_files.py /path/to/l10n/directory
"""

import json
import sys
from pathlib import Path
from collections import defaultdict
import subprocess




def sort_arb_file(file_path):
    """Sort a single ARB file alphabetically."""
    print(f"Processing {file_path}...")

    # Read the file, handle malformed JSON gracefully
    import re
    data = None
    with open(file_path, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"  ⚠️  Malformed JSON in {file_path}: {e}")
            # Attempt to fix common ARB JSON issues
            f.seek(0)
            content = f.read()
            # Remove trailing commas before } or ]
            content_fixed = re.sub(r',(\s*[}\]])', r'\1', content)
            # Insert missing commas between string entries on separate lines
            # This is a naive fix: looks for lines ending with " and next line starting with "
            lines = content_fixed.splitlines()
            fixed_lines = []
            for i, line in enumerate(lines):
                fixed_lines.append(line)
                if (
                    line.rstrip().endswith('"')
                    and i + 1 < len(lines)
                    and re.match(r'\s*"', lines[i + 1])
                ):
                    # Add comma if not already at end of an object or array
                    if not line.rstrip().endswith(','):
                        fixed_lines[-1] = line.rstrip() + ','
            content_fixed2 = "\n".join(fixed_lines)
            try:
                data = json.loads(content_fixed2)
                print(f"  ⚠️  Fixed malformed JSON and continued processing.")
            except json.JSONDecodeError as e2:
                print(f"  ❌ Still invalid after attempted fix: {e2}")
                print(f"  Skipping {file_path}. Please fix the file manually.")
                return 0

    # Separate regular keys and placeholder keys (@keys), keeping last occurrence
    regular_keys = {}
    placeholder_keys = {}

    for key, value in data.items():
        if key.startswith('@'):
            # Keep last occurrence of placeholder key
            placeholder_keys[key[1:]] = (key, value)  # Store with base key
        else:
            # Keep last occurrence of regular key
            regular_keys[key] = value

    # Sort regular keys alphabetically
    sorted_regular_keys = sorted(regular_keys.keys())

    # Build the sorted data, ensuring placeholders come right after their main keys
    sorted_data = {}

    for key in sorted_regular_keys:
        # Add the regular key
        sorted_data[key] = regular_keys[key]

        # Add the corresponding placeholder if it exists
        if key in placeholder_keys:
            placeholder_key, placeholder_value = placeholder_keys[key]
            sorted_data[placeholder_key] = placeholder_value

    original_count = len(data)
    final_count = len(sorted_data)

    # Write back the sorted data
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(sorted_data, f, indent=2, ensure_ascii=False)

    if original_count == final_count:
        print(f"  ✅ Sorted successfully (maintained {final_count} unique entries)")
    else:
        print(f"  ⚠️  Warning: Removed duplicates, entry count changed from {original_count} to {final_count}")

    return final_count


def main():
    """Main function to process ARB files."""
    # Default to lib/l10n directory
    l10n_dir = Path("lib/l10n")

    # Allow custom directory from command line
    if len(sys.argv) > 1:
        l10n_dir = Path(sys.argv[1])

    if not l10n_dir.exists():
        print(f"Error: Directory {l10n_dir} does not exist!")
        sys.exit(1)

    # Find all ARB files
    arb_files = list(l10n_dir.glob("*.arb"))

    if not arb_files:
        print(f"No ARB files found in {l10n_dir}")
        print("Make sure you're in the Flutter project root directory.")
        sys.exit(1)

    print(f"Found {len(arb_files)} ARB file(s) to sort:")
    for arb_file in arb_files:
        print(f"  • {arb_file.name}")
    print()

    # Sort each file
    total_files = 0
    for arb_file in sorted(arb_files):  # Sort filenames for consistent output
        entries = sort_arb_file(arb_file)
        total_files += 1

    print("✅ ARB file sorting completed!")
    print(f"Processed {total_files} file(s)")

    print("To regenerate localization files, run:")
    print("  flutter gen-l10n")

    # --- Delta key analysis for EN vs ES and FR ---
    # Read app_en.arb, app_es.arb, app_fr.arb from l10n_dir
    en_path = l10n_dir / "app_en.arb"
    es_path = l10n_dir / "app_es.arb"
    fr_path = l10n_dir / "app_fr.arb"
    def read_keys(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                # Include all keys (regular and placeholders)
                return set(data.keys())
        except Exception as e:
            print(f"  ⚠️  Could not read {path.name}: {e}")
            return set()
    en_keys = read_keys(en_path)
    es_keys = read_keys(es_path)
    fr_keys = read_keys(fr_path)
    if en_keys:
        missing_in_es = sorted(en_keys - es_keys)
        missing_in_fr = sorted(en_keys - fr_keys)
        extra_in_es = sorted(es_keys - en_keys)
        extra_in_fr = sorted(fr_keys - en_keys)
        print("\n=== Delta Key Analysis (EN vs ES/FR) ===")
        if missing_in_es:
            print(f"Keys in EN but missing in ES ({len(missing_in_es)}):")
            for k in missing_in_es:
                print(f"  - {k}")
        else:
            print("No keys missing in ES.")
        if extra_in_es:
            print(f"Extra keys in ES not in EN ({len(extra_in_es)}):")
            for k in extra_in_es:
                print(f"  - {k}")
        else:
            print("No extra keys in ES.")
        if missing_in_fr:
            print(f"Keys in EN but missing in FR ({len(missing_in_fr)}):")
            for k in missing_in_fr:
                print(f"  - {k}")
        else:
            print("No keys missing in FR.")
        if extra_in_fr:
            print(f"Extra keys in FR not in EN ({len(extra_in_fr)}):")
            for k in extra_in_fr:
                print(f"  - {k}")
        else:
            print("No extra keys in FR.")


        # Load full EN data
        try:
            with open(en_path, "r", encoding="utf-8") as f:
                en_data = json.load(f)
        except Exception as e:
            print(f"  ⚠️  Could not read {en_path.name} for translation: {e}")
            en_data = {}

        # Update ES ARB
        try:
            with open(es_path, "r", encoding="utf-8") as f:
                es_data = json.load(f)
        except Exception as e:
            print(f"  ⚠️  Could not read {es_path.name} for updating: {e}")
            es_data = {}

        # Remove extra keys from ES
        removed_es = 0
        for key in extra_in_es:
            if key in es_data:
                del es_data[key]
                removed_es += 1
            placeholder_key = "@" + key if not key.startswith("@") else key
            if placeholder_key in es_data:
                del es_data[placeholder_key]
                removed_es += 1

        # Add missing keys to ES
        added_es = 0
        for key in missing_in_es:
            if key.startswith("@"):
                # Placeholder key, copy directly if exists in EN
                if key in en_data:
                    es_data[key] = en_data[key]
                    added_es += 1
            else:
                # Regular key, copy English as placeholder
                if key in en_data:
                    es_data[key] = en_data[key]
                    # Also copy placeholder if exists
                    placeholder_key = "@" + key
                    if placeholder_key in en_data:
                        es_data[placeholder_key] = en_data[placeholder_key]
                    added_es += 1

        # Remove [ES] translation stub handling; no translation
        updated_es = 0

        # Write back updated ES ARB
        with open(es_path, "w", encoding="utf-8") as f:
            json.dump(es_data, f, indent=2, ensure_ascii=False)
        print(f"Removed {removed_es} extra keys and added {added_es} missing keys to {es_path.name}.")
        print(f"Translated {updated_es} entries in {es_path.name}.")

        # Re-sort ES ARB file
        sort_arb_file(es_path)

        # Update FR ARB
        try:
            with open(fr_path, "r", encoding="utf-8") as f:
                fr_data = json.load(f)
        except Exception as e:
            print(f"  ⚠️  Could not read {fr_path.name} for updating: {e}")
            fr_data = {}

        # Remove extra keys from FR
        removed_fr = 0
        for key in extra_in_fr:
            if key in fr_data:
                del fr_data[key]
                removed_fr += 1
            placeholder_key = "@" + key if not key.startswith("@") else key
            if placeholder_key in fr_data:
                del fr_data[placeholder_key]
                removed_fr += 1

        # Add missing keys to FR
        added_fr = 0
        for key in missing_in_fr:
            if key.startswith("@"):
                # Placeholder key, copy directly if exists in EN
                if key in en_data:
                    fr_data[key] = en_data[key]
                    added_fr += 1
            else:
                # Regular key, copy English as placeholder
                if key in en_data:
                    fr_data[key] = en_data[key]
                    # Also copy placeholder if exists
                    placeholder_key = "@" + key
                    if placeholder_key in en_data:
                        fr_data[placeholder_key] = en_data[placeholder_key]
                    added_fr += 1

        # Remove [FR] translation stub handling; no translation
        updated_fr = 0

        # Write back updated FR ARB
        with open(fr_path, "w", encoding="utf-8") as f:
            json.dump(fr_data, f, indent=2, ensure_ascii=False)
        print(f"Removed {removed_fr} extra keys and added {added_fr} missing keys to {fr_path.name}.")
        print(f"Translated {updated_fr} entries in {fr_path.name}.")

        # Re-sort FR ARB file
        sort_arb_file(fr_path)

        # After updates, verify all have same total entries count and keys
        try:
            with open(en_path, "r", encoding="utf-8") as f:
                en_data_final = json.load(f)
            with open(es_path, "r", encoding="utf-8") as f:
                es_data_final = json.load(f)
            with open(fr_path, "r", encoding="utf-8") as f:
                fr_data_final = json.load(f)
            en_count = len(en_data_final)
            es_count = len(es_data_final)
            fr_count = len(fr_data_final)
            en_keys_final = set(en_data_final.keys())
            es_keys_final = set(es_data_final.keys())
            fr_keys_final = set(fr_data_final.keys())
            print("\n=== Final Entry Counts ===")
            print(f"EN: {en_count} entries")
            print(f"ES: {es_count} entries")
            print(f"FR: {fr_count} entries")
            if en_keys_final == es_keys_final == fr_keys_final:
                print("✅ All ARB files have matching keys including placeholders.")
            else:
                print("⚠️  Warning: ARB files do not have matching keys.")
                missing_in_es_final = en_keys_final - es_keys_final
                missing_in_fr_final = en_keys_final - fr_keys_final
                extra_in_es_final = es_keys_final - en_keys_final
                extra_in_fr_final = fr_keys_final - en_keys_final
                if missing_in_es_final:
                    print(f"Keys missing in ES after update ({len(missing_in_es_final)}):")
                    for k in sorted(missing_in_es_final):
                        print(f"  - {k}")
                if extra_in_es_final:
                    print(f"Extra keys in ES after update ({len(extra_in_es_final)}):")
                    for k in sorted(extra_in_es_final):
                        print(f"  - {k}")
                if missing_in_fr_final:
                    print(f"Keys missing in FR after update ({len(missing_in_fr_final)}):")
                    for k in sorted(missing_in_fr_final):
                        print(f"  - {k}")
                if extra_in_fr_final:
                    print(f"Extra keys in FR after update ({len(extra_in_fr_final)}):")
                    for k in sorted(extra_in_fr_final):
                        print(f"  - {k}")
        except Exception as e:
            print(f"  ⚠️  Could not verify final entry counts: {e}")

    import subprocess
    print("\nRunning 'flutter gen-l10n' to regenerate localization files...")
    try:
        subprocess.run(["flutter", "gen-l10n"], check=True)
        print("✅ 'flutter gen-l10n' completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error running 'flutter gen-l10n': {e}")
    except FileNotFoundError:
        print("❌ 'flutter' command not found. Please ensure Flutter SDK is installed and in your PATH.")


if __name__ == "__main__":
    main()
