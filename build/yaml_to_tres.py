#!/usr/bin/env python3
"""
YAML to Godot Resource (.tres) Converter
Converts design data YAML files to Godot Resource files for fast runtime loading.

Usage:
    python yaml_to_tres.py --input-dir docs/design/data --output-dir src/data --verbose
"""

import argparse
import os
import sys
import yaml
from pathlib import Path
from datetime import datetime
from typing import Any, Dict, List, Optional


class TresConverter:
    """Converts YAML data to Godot .tres resource format."""

    # Mapping from YAML file base name to resource class and output subdirectory
    RESOURCE_MAPPINGS = {
        'train-cars': {
            'class_name': 'TrainCarData',
            'script_path': 'res://src/data/types/train_car_data.gd',
            'data_keys': ['cars', 'subsystems'],
            'output_subdir': 'train_cars',
        },
        'professions': {
            'class_name': 'ProfessionData',
            'script_path': 'res://src/data/types/profession_data.gd',
            'data_keys': ['professions'],
            'output_subdir': 'professions',
        },
        'resources': {
            'class_name': 'ResourceItemData',
            'script_path': 'res://src/data/types/resource_item_data.gd',
            'data_keys': ['common_resources', 'structured_resources', 'milestone_resources'],
            'output_subdir': 'resources',
        },
        'upgrades': {
            'class_name': 'UpgradeData',
            'script_path': 'res://src/data/types/upgrade_data.gd',
            'data_keys': None,  # Special handling - nested by car
            'output_subdir': 'upgrades',
        },
        'locations': {
            'class_name': 'LocationData',
            'script_path': 'res://src/data/types/location_data.gd',
            'data_keys': ['locations'],
            'output_subdir': 'locations',
        },
        'recipes': {
            'class_name': 'RecipeData',
            'script_path': 'res://src/data/types/recipe_data.gd',
            'data_keys': ['consumables', 'ammunition', 'medical', 'repair_kits',
                          'tools', 'equipment', 'train_parts', 'specialty', 'conversion'],
            'output_subdir': 'recipes',
        },
    }

    def __init__(self, input_dir: str, output_dir: str, verbose: bool = False):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.verbose = verbose
        self.manifest = {
            'generated_at': datetime.now().isoformat(),
            'source_dir': str(self.input_dir),
            'output_dir': str(self.output_dir),
            'files': [],
        }

    def log(self, message: str):
        """Log message if verbose mode is enabled."""
        if self.verbose:
            print(f"  {message}")

    def escape_string(self, value: str) -> str:
        """Escape string for .tres format."""
        if value is None:
            return '""'
        escaped = str(value).replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
        return f'"{escaped}"'

    def format_value(self, value: Any, indent: int = 0) -> str:
        """Format a Python value for .tres format."""
        indent_str = "  " * indent

        if value is None:
            return 'null'
        elif isinstance(value, bool):
            return 'true' if value else 'false'
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, str):
            return self.escape_string(value)
        elif isinstance(value, list):
            if not value:
                return '[]'
            # Check if it's a simple list (all primitives)
            if all(isinstance(v, (str, int, float, bool)) or v is None for v in value):
                formatted = [self.format_value(v) for v in value]
                return f"[{', '.join(formatted)}]"
            else:
                # Complex list - format with newlines
                lines = ['[']
                for item in value:
                    lines.append(f"{indent_str}  {self.format_value(item, indent + 1)},")
                lines.append(f"{indent_str}]")
                return '\n'.join(lines)
        elif isinstance(value, dict):
            if not value:
                return '{}'
            lines = ['{']
            for k, v in value.items():
                formatted_val = self.format_value(v, indent + 1)
                lines.append(f'{indent_str}  "{k}": {formatted_val},')
            lines.append(f'{indent_str}}}')
            return '\n'.join(lines)
        else:
            return self.escape_string(str(value))

    def generate_tres_content(self, data: Dict[str, Any], script_path: str, resource_id: str) -> str:
        """Generate .tres file content for a single resource."""
        lines = [
            f'[gd_resource type="Resource" script_class="{script_path.split("/")[-1].replace(".gd", "").title().replace("_", "")}" load_steps=2 format=3]',
            '',
            f'[ext_resource type="Script" path="{script_path}" id="1"]',
            '',
            '[resource]',
            'script = ExtResource("1")',
        ]

        # Add all data properties
        for key, value in data.items():
            formatted = self.format_value(value)
            lines.append(f'{key} = {formatted}')

        return '\n'.join(lines) + '\n'

    def convert_train_cars(self, yaml_data: Dict) -> List[Dict]:
        """Convert train cars YAML to individual resources."""
        resources = []

        # Convert cars
        for car in yaml_data.get('cars', []):
            car_data = dict(car)
            car_data['type'] = 'car'
            resources.append({
                'id': car['id'],
                'data': car_data,
                'type': 'car'
            })

        # Convert subsystems as separate resources
        for subsystem in yaml_data.get('subsystems', []):
            subsystem_data = dict(subsystem)
            subsystem_data['type'] = 'subsystem'
            resources.append({
                'id': f"subsystem_{subsystem['id']}",
                'data': subsystem_data,
                'type': 'subsystem'
            })

        return resources

    def convert_professions(self, yaml_data: Dict) -> List[Dict]:
        """Convert professions YAML to individual resources."""
        resources = []
        for profession in yaml_data.get('professions', []):
            resources.append({
                'id': profession['id'],
                'data': profession,
                'type': 'profession'
            })
        return resources

    def convert_resources(self, yaml_data: Dict) -> List[Dict]:
        """Convert resources YAML to individual resources."""
        resources = []
        for category_key in ['common_resources', 'structured_resources', 'milestone_resources']:
            for item in yaml_data.get(category_key, []):
                resources.append({
                    'id': item['id'],
                    'data': item,
                    'type': 'resource_item'
                })
        return resources

    def convert_upgrades(self, yaml_data: Dict) -> List[Dict]:
        """Convert upgrades YAML to individual resources."""
        resources = []

        # Upgrades are organized by car (engine_car, cargo_car, etc.)
        for car_id, car_data in yaml_data.items():
            if not isinstance(car_data, dict):
                continue

            # Core upgrades
            for upgrade in car_data.get('core', []):
                upgrade_data = dict(upgrade)
                upgrade_data['car'] = car_id
                upgrade_data['path'] = 'core'
                resources.append({
                    'id': upgrade['id'],
                    'data': upgrade_data,
                    'type': 'upgrade'
                })

            # Side upgrades
            for upgrade in car_data.get('side', []):
                upgrade_data = dict(upgrade)
                upgrade_data['car'] = car_id
                upgrade_data['path'] = 'side'
                resources.append({
                    'id': upgrade['id'],
                    'data': upgrade_data,
                    'type': 'upgrade'
                })

        return resources

    def convert_locations(self, yaml_data: Dict) -> List[Dict]:
        """Convert locations YAML to individual resources."""
        resources = []
        for location in yaml_data.get('locations', []):
            resources.append({
                'id': location['id'],
                'data': location,
                'type': 'location'
            })
        return resources

    def convert_recipes(self, yaml_data: Dict) -> List[Dict]:
        """Convert recipes YAML to individual resources."""
        resources = []
        category_keys = ['consumables', 'ammunition', 'medical', 'repair_kits',
                        'tools', 'equipment', 'train_parts', 'specialty', 'conversion']

        for category_key in category_keys:
            for recipe in yaml_data.get(category_key, []):
                recipe_data = dict(recipe)
                recipe_data['recipe_category'] = category_key
                resources.append({
                    'id': recipe['id'],
                    'data': recipe_data,
                    'type': 'recipe'
                })
        return resources

    def convert_file(self, yaml_file: str) -> int:
        """Convert a single YAML file to .tres resources."""
        file_path = self.input_dir / yaml_file
        base_name = yaml_file.replace('.yaml', '')

        if base_name not in self.RESOURCE_MAPPINGS:
            print(f"Warning: No mapping for {yaml_file}, skipping")
            return 0

        mapping = self.RESOURCE_MAPPINGS[base_name]

        with open(file_path, 'r', encoding='utf-8') as f:
            yaml_data = yaml.safe_load(f)

        # Convert based on file type
        converter_map = {
            'train-cars': self.convert_train_cars,
            'professions': self.convert_professions,
            'resources': self.convert_resources,
            'upgrades': self.convert_upgrades,
            'locations': self.convert_locations,
            'recipes': self.convert_recipes,
        }

        resources = converter_map[base_name](yaml_data)

        # Create output directory
        output_subdir = self.output_dir / mapping['output_subdir']
        output_subdir.mkdir(parents=True, exist_ok=True)

        # Write each resource
        count = 0
        for resource in resources:
            output_file = output_subdir / f"{resource['id']}.tres"
            content = self.generate_tres_content(
                resource['data'],
                mapping['script_path'],
                resource['id']
            )

            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(content)

            self.log(f"  Generated: {output_file.name}")
            self.manifest['files'].append({
                'source': yaml_file,
                'output': str(output_file.relative_to(self.output_dir)),
                'id': resource['id'],
                'type': resource['type'],
            })
            count += 1

        return count

    def convert_all(self) -> Dict:
        """Convert all YAML files to .tres resources."""
        yaml_files = [
            'train-cars.yaml',
            'professions.yaml',
            'resources.yaml',
            'upgrades.yaml',
            'locations.yaml',
            'recipes.yaml',
        ]

        total_count = 0

        print(f"Converting YAML files from {self.input_dir}")
        print(f"Output directory: {self.output_dir}")
        print()

        for yaml_file in yaml_files:
            print(f"Processing {yaml_file}...")
            count = self.convert_file(yaml_file)
            print(f"  Generated {count} resources")
            total_count += count

        print()
        print(f"Total resources generated: {total_count}")

        # Write manifest
        manifest_path = self.output_dir / 'manifest.tres'
        manifest_content = self.generate_tres_content(
            self.manifest,
            'res://src/data/types/manifest_data.gd',
            'manifest'
        )

        # For manifest, just write as JSON-like format since it's metadata
        manifest_json_path = self.output_dir / 'manifest.json'
        import json
        with open(manifest_json_path, 'w', encoding='utf-8') as f:
            json.dump(self.manifest, f, indent=2)
        print(f"Manifest written to: {manifest_json_path}")

        return self.manifest


def main():
    parser = argparse.ArgumentParser(
        description='Convert YAML design data to Godot .tres resource files'
    )
    parser.add_argument(
        '--input-dir', '-i',
        default='docs/design/data',
        help='Input directory containing YAML files'
    )
    parser.add_argument(
        '--output-dir', '-o',
        default='src/data',
        help='Output directory for .tres files'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output'
    )

    args = parser.parse_args()

    # Resolve paths relative to script location or current directory
    script_dir = Path(__file__).parent.parent
    input_dir = script_dir / args.input_dir if not Path(args.input_dir).is_absolute() else Path(args.input_dir)
    output_dir = script_dir / args.output_dir if not Path(args.output_dir).is_absolute() else Path(args.output_dir)

    if not input_dir.exists():
        print(f"Error: Input directory does not exist: {input_dir}")
        sys.exit(1)

    converter = TresConverter(input_dir, output_dir, args.verbose)
    converter.convert_all()


if __name__ == '__main__':
    main()
