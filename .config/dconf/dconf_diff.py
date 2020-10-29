#!/usr/bin/env python3
import argparse
import configparser
import re
import sys

IGNORED_OPTION_RES = [
    '.*/last-save-directory',
    '.*/last-viewed-location',
    'ca/desrt/dconf-editor/saved-view',
    'ca/desrt/dconf-editor/saved-pathbar-path',
    '.*/sidebar-width',
    # 'version',
    '.*/height',
    '.*/width',
    '.*/.*window-(height|width|size|maximized|is-maximized|position|geometry)',
    '.*/column-width',
    '.*/file-chooser/sort-*',
    '.*/file-chooser/show-hidden',
    '.*/file-chooser/show-type-column',
    '.*/file-chooser/show-size-column',
    '.*/file-chooser/type-format',
    'apps/seahorse/listing/item-filter',
    'org/gnome/charmap/last-char',
    'org/gnome/charmap/window-state/size',
    'org/gnome/desktop/privacy/disable-microphone',
    'org/gnome/feedreader/inoreader',
    'org/gnome/feedreader/saved-state',
    'org/gnome/file-roller/listing',
    'org/gnome/gnome-screenshot/(delay|include-pointer)',
    'org/gtk/settings/color-chooser/custom-colors',
    'org/gtk/settings/color-chooser/selected-color',
    'org/virt-manager/virt-manager/paths/(media|image)-default',
    'org/virt-manager/virt-manager/urls',
    'org/virt-manager/virt-manager/vmlist-fields',
]
IGNORED_OPTION_RES = [re.compile(r) for r in IGNORED_OPTION_RES]


def _filter_options(section, options):
    result = []
    for option in options:
        option_full_name = '{}/{}'.format(section, option)
        if not any(r.match(option_full_name) for r in IGNORED_OPTION_RES):
            result.append(option)
    return result


def main():
    parser = argparse.ArgumentParser(description='Diff dconf settings')
    parser.add_argument('--base-configs', required=True)
    parser.add_argument('--other-configs', required=True)
    args = parser.parse_args()
    base_config_parser = configparser.ConfigParser()
    for path in args.base_configs.split(','):
        with open(path) as f:
            base_config_parser.read_file(f)
    other_config_parser = configparser.ConfigParser()
    for path in args.other_configs.split(','):
        with open(path) as f:
            other_config_parser.read_file(f)
    all_sections = set(base_config_parser.sections() +
                       other_config_parser.sections())
    has_diff = False
    for section in sorted(all_sections):
        all_options = set()
        if base_config_parser.has_section(section):
            all_options.update(base_config_parser.options(section))
        if other_config_parser.has_section(section):
            all_options.update(other_config_parser.options(section))
        all_options = _filter_options(section, all_options)
        output_lines = []
        for option in sorted(all_options):
            base_value = base_config_parser.get(section,
                                                option,
                                                raw=True,
                                                fallback=None)
            other_value = other_config_parser.get(section,
                                                  option,
                                                  raw=True,
                                                  fallback=None)
            if base_value is None:
                output_lines.append('Added option: {}={}'.format(
                    option, other_value))
            elif other_value is None:
                output_lines.append('Removed option: {}={}'.format(
                    option, base_value))
            elif other_value != base_value:
                output_lines.append('Option: {} changed from {} to {}'.format(
                    option, base_value, other_value))
        if output_lines:
            has_diff = True
            print('-' * 80)
            print('section: {}'.format(section))
            print('-' * 80)
            print('\n'.join(output_lines))
            print()
    sys.exit(has_diff)


if __name__ == '__main__':
    main()
