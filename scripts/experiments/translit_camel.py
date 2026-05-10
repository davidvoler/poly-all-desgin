"""Arabic transliteration using camel-tools (no Java needed).

Two stages:
  1. Diacritize unvocalized text (adds short vowels) using camel-tools'
     MLE disambiguator — picks the most likely analysis per token.
  2. Transliterate the vocalized text using a CharMapper scheme.

Schemes available out of the box:
  - ar2bw      Buckwalter (reversible ASCII, ugly)
  - ar2safebw  Safe Buckwalter (no special chars)
  - ar2hsb     Habash-Soudi-Buckwalter (more readable)
  - ar2arabtex ArabTeX
"""

from camel_tools.disambig.mle import MLEDisambiguator
from camel_tools.tokenizers.word import simple_word_tokenize
from camel_tools.utils.charmap import CharMapper

mle = MLEDisambiguator.pretrained()
ar2bw = CharMapper.builtin_mapper('ar2bw')
ar2safebw = CharMapper.builtin_mapper('ar2safebw')
ar2hsb = CharMapper.builtin_mapper('ar2hsb')


def diacritize(text: str) -> str:
    tokens = simple_word_tokenize(text)
    disambig = mle.disambiguate(tokens)
    out = []
    for tok, d in zip(tokens, disambig):
        if d.analyses:
            out.append(d.analyses[0].analysis.get('diac', tok))
        else:
            out.append(tok)
    return ' '.join(out)


def transliterate(text: str) -> dict:
    vocalized = diacritize(text)
    return {
        'original': text,
        'vocalized': vocalized,
        'buckwalter': ar2bw(vocalized),
        'safe_bw': ar2safebw(vocalized),
        'hsb': ar2hsb(vocalized),
    }


if __name__ == '__main__':
    samples = [
        'ذهب الولد إلى المدرسة',
        'مرحبا بالعالم',
        'القاهرة',
        'محمد',
    ]
    for s in samples:
        r = transliterate(s)
        print(f"Original:   {r['original']}")
        print(f"Vocalized:  {r['vocalized']}")
        print(f"Buckwalter: {r['buckwalter']}")
        print(f"SafeBW:     {r['safe_bw']}")
        print(f"HSB:        {r['hsb']}")
        print('-' * 50)
