# -*- coding: utf-8 -*-
"""Writes lib/l10n/app_{fr,en,ar}.arb from tool/i18n/strings.py.

    python tool/i18n/build_arb.py && flutter gen-l10n
"""
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from strings import S  # noqa: E402

OUT = os.path.join(HERE, '..', '..', 'lib', 'l10n')

# The placeholders a message actually references (ICU plural variables and
# plain {name} ones), used to catch a translation that drops or invents one.
_VAR = re.compile(r'\{([A-Za-z_][A-Za-z0-9_]*)(?:,|\})')


def used(msg):
    return set(_VAR.findall(msg))


def main():
    keys = set()
    problems = []
    arbs = {'fr': {'@@locale': 'fr'}, 'en': {'@@locale': 'en'}, 'ar': {'@@locale': 'ar'}}
    for key, fr, en, ar, params in S:
        if key in keys:
            problems.append(f'duplicate key {key}')
        keys.add(key)
        declared = set(params)
        for lang, msg in (('fr', fr), ('en', en), ('ar', ar)):
            u = used(msg) - {'plural'}
            if u != declared:
                problems.append(f'{key}[{lang}]: uses {sorted(u)}, declares {sorted(declared)}')
            arbs[lang][key] = msg
        if params:
            arbs['fr'][f'@{key}'] = {
                'placeholders': {name: {'type': t} for name, t in params.items()}
            }
    if problems:
        print('\n'.join(problems))
        sys.exit(1)
    os.makedirs(OUT, exist_ok=True)
    for lang, data in arbs.items():
        with io.open(os.path.join(OUT, f'app_{lang}.arb'), 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print(f'{len(S)} messages x 3 languages written to {os.path.normpath(OUT)}')


if __name__ == '__main__':
    main()
