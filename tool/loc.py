#!/usr/bin/env python3
"""
Script to normalize Flutter ARB (Application Resource Bundle) files.

This script preserves the existing key order in ARB files, appends any missing
keys, removes extra keys, and keeps placeholder definitions (@keys) aligned
with their corresponding translation keys when new entries are added.

Usage:
    python tool/loc.py
    # or
    python tool/loc.py /path/to/l10n/directory
"""

import json
import sys
from pathlib import Path
import subprocess


def normalize_arb_file(file_path: Path) -> int:
    """Rewrite a single ARB file while preserving its current key order."""
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

    original_count = len(data)

    # Write back the normalized data without reordering keys.
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    final_count = len(data)
    print(f"  ✅ Normalized successfully (maintained {final_count} entries)")
    return final_count


def should_skip_translation(data: dict[str, object], key: str) -> bool:
    """Return whether a key is marked to skip translation via ARB metadata."""
    metadata_key = f"@{key}"
    metadata = data.get(metadata_key)
    if not isinstance(metadata, dict):
        return False

    description = metadata.get("description")
    if not isinstance(description, str):
        return False

    normalized_description = description.strip().lower()
    return normalized_description in {"reviewed", "ignored"}


def should_preserve_extra_key(data: dict[str, object], key: str) -> bool:
    """Return whether an extra ARB key should be preserved during cleanup."""
    if not key.startswith("@"):
        return False

    base_key = key[1:]
    if base_key not in data:
        return False

    return should_skip_translation(data, base_key)


def copy_missing_keys(
    source_data: dict[str, object],
    target_data: dict[str, object],
    missing_keys: list[str],
    locale_name: str,
) -> tuple[int, int]:
    """Copy missing keys from the source ARB into the target ARB without translating."""
    added_count = 0
    skipped_translation_count = 0

    for key in missing_keys:
        if key.startswith("@"):
            if key in source_data:
                target_data[key] = source_data[key]
                added_count += 1
            continue

        if key not in source_data:
            continue

        if should_skip_translation(source_data, key):
            skipped_translation_count += 1
            print(
                f"  • Skipping translation for {locale_name}:{key} "
                "because @key.description is REVIEWED/IGNORED."
            )

        target_data[key] = source_data[key]
        placeholder_key = f"@{key}"
        if placeholder_key in source_data:
            target_data[placeholder_key] = source_data[placeholder_key]
        added_count += 1

    return added_count, skipped_translation_count


def main() -> None:
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

    print(f"Found {len(arb_files)} ARB file(s) to normalize:")
    for arb_file in arb_files:
        print(f"  • {arb_file.name}")
    print()

    # Normalize each file without changing key order.
    total_files = 0
    for arb_file in sorted(arb_files):
        entries = normalize_arb_file(arb_file)
        total_files += 1

    print("✅ ARB file normalization completed!")
    print(f"Processed {total_files} file(s)")

    print("To regenerate localization files, run:")
    print("  flutter gen-l10n")

    # --- Delta key analysis for EN vs ES and FR ---
    # Read app_en.arb, app_es.arb, app_fr.arb from l10n_dir
    en_path = l10n_dir / "app_en.arb"
    es_path = l10n_dir / "app_es.arb"
    fr_path = l10n_dir / "app_fr.arb"
    def read_keys(path: Path) -> set[str]:
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
            if should_preserve_extra_key(es_data, key):
                continue
            if key in es_data:
                del es_data[key]
                removed_es += 1
            placeholder_key = "@" + key if not key.startswith("@") else key
            if placeholder_key in es_data:
                del es_data[placeholder_key]
                removed_es += 1

        # Add missing keys to ES
        added_es, skipped_translation_es = copy_missing_keys(
            source_data=en_data,
            target_data=es_data,
            missing_keys=missing_in_es,
            locale_name="es",
        )

        # Remove [ES] translation stub handling; no translation
        updated_es = 0

        # Write back updated ES ARB
        with open(es_path, "w", encoding="utf-8") as f:
            json.dump(es_data, f, indent=2, ensure_ascii=False)
        print(f"Removed {removed_es} extra keys and added {added_es} missing keys to {es_path.name}.")
        print(f"Skipped translation for {skipped_translation_es} reviewed/ignored entries in {es_path.name}.")
        print(f"Translated {updated_es} entries in {es_path.name}.")

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
            if should_preserve_extra_key(fr_data, key):
                continue
            if key in fr_data:
                del fr_data[key]
                removed_fr += 1
            placeholder_key = "@" + key if not key.startswith("@") else key
            if placeholder_key in fr_data:
                del fr_data[placeholder_key]
                removed_fr += 1

        # Add missing keys to FR
        added_fr, skipped_translation_fr = copy_missing_keys(
            source_data=en_data,
            target_data=fr_data,
            missing_keys=missing_in_fr,
            locale_name="fr",
        )

        # Remove [FR] translation stub handling; no translation
        updated_fr = 0

        # Write back updated FR ARB
        with open(fr_path, "w", encoding="utf-8") as f:
            json.dump(fr_data, f, indent=2, ensure_ascii=False)
        print(f"Removed {removed_fr} extra keys and added {added_fr} missing keys to {fr_path.name}.")
        print(f"Skipped translation for {skipped_translation_fr} reviewed/ignored entries in {fr_path.name}.")
        print(f"Translated {updated_fr} entries in {fr_path.name}.")

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
            comparable_es_keys_final = {
                key for key in es_keys_final
                if not (key not in en_keys_final and should_preserve_extra_key(es_data_final, key))
            }
            comparable_fr_keys_final = {
                key for key in fr_keys_final
                if not (key not in en_keys_final and should_preserve_extra_key(fr_data_final, key))
            }
            print("\n=== Final Entry Counts ===")
            print(f"EN: {en_count} entries")
            print(f"ES: {es_count} entries")
            print(f"FR: {fr_count} entries")
            if en_keys_final == comparable_es_keys_final == comparable_fr_keys_final:
                print("✅ All ARB files have matching keys including placeholders.")
            else:
                print("⚠️  Warning: ARB files do not have matching keys.")
                missing_in_es_final = en_keys_final - comparable_es_keys_final
                missing_in_fr_final = en_keys_final - comparable_fr_keys_final
                extra_in_es_final = comparable_es_keys_final - en_keys_final
                extra_in_fr_final = comparable_fr_keys_final - en_keys_final
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
