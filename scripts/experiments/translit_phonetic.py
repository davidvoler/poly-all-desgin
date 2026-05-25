import unicodedata
from farasa.diacratizer import FarasaDiacritizer
dg = FarasaDiacritizer()

# Phonetic (ALA-LC-ish) transliteration map.
# Produces output that's pronounceable to English readers.
phonetic_map = {
    # Consonants
    'ب': 'b',  'ت': 't',  'ث': 'th', 'ج': 'j',  'ح': 'h',
    'خ': 'kh', 'د': 'd',  'ذ': 'dh', 'ر': 'r',  'ز': 'z',
    'س': 's',  'ش': 'sh', 'ص': 's',  'ض': 'd',  'ط': 't',
    'ظ': 'z',  'ع': 'a',  'غ': 'gh', 'ف': 'f',  'ق': 'q',
    'ك': 'k',  'ل': 'l',  'م': 'm',  'ن': 'n',  'ه': 'h',
    'و': 'w',  'ي': 'y',

    # Hamza variants
    'ء': "'", 'أ': 'a', 'إ': 'i', 'آ': 'aa', 'ؤ': "u'", 'ئ': "i'",

    # Vowels & long vowels
    'ا': 'a', 'ى': 'a',

    # Ta marbuta (often silent or 't' in construct)
    'ة': 'h',

    # Short vowel diacritics
    'َ': 'a',  # Fatha
    'ُ': 'u',  # Damma
    'ِ': 'i',  # Kasra
    'ً': 'an', # Fathatan
    'ٌ': 'un', # Dammatan
    'ٍ': 'in', # Kasratan
    'ْ': '',   # Sukun (no vowel)

    # Punctuation
    '،': ',', '؛': ';', '؟': '?',
}


def transliterate(text: str) -> str:
    text = unicodedata.normalize('NFC', text)
    out = []
    for ch in text:
        if ch in phonetic_map:
            out.append(phonetic_map[ch])
        elif ch == 'ّ':  # Shadda — double the previous consonant
            if out and out[-1]:
                out.append(out[-1][-1])
        else:
            out.append(ch)
    return ''.join(out)


if __name__ == '__main__':
    samples = [
        'ذهب الولد إلى المدرسة',
        'مرحبا بالعالم',
        'القاهرة',
        'محمّد',
    ]
    for s in samples:
        diac_s = dg.diacritize(s)
        print(f'{s:<30} -> {diac_s}')
        print(f'{s:<30} -> {transliterate(s)}')
