from farasa.diacratizer import FarasaDiacritizer

# 1. Initialize Farasa
dg = FarasaDiacritizer()

# 2. Define the Buckwalter Map (Core subset)
# This maps Arabic letters and diacritics to specific ASCII symbols.
buckwalter_map = {
    # Consonants
    'ب': 'b', 'ت': 't', 'ث': 'v', 'ج': 'j', 'ح': 'H', 'خ': 'x', 
    'د': 'd', 'ذ': '*','ر': 'r', 'ز': 'z', 'س': 's', 'ش': '$', 
    'ص': 'S', 'ض': 'D', 'ط': 'T', 'ظ': 'Z', 'ع': 'E', 'غ': 'g', 
    'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 
    'ه': 'h', 'و': 'w', 'ي': 'y', 'ة': 'p', 'أ': '>', 'إ': '<',
    
    # Diacritics (Short Vowels)
    'َ': 'a', # Fatha
    'ُ': 'u', # Damma
    'ِ': 'i', # Kasra
    'ّ': '~', # Shadda (Doubled letter)
    'ْ': 'o', # Sukun (No vowel)
}

def transliterate_to_buckwalter(arabic_text):
    # Use Farasa to add vowels so our transliteration is complete
    vocalized = dg.diacritize(arabic_text)
    
    # Map each character to its Buckwalter equivalent
    result = "".join([buckwalter_map.get(char, char) for char in vocalized])
    return result

# 3. Test it out
sentence = "ذهب الولد إلى المدرسة"
encoded = transliterate_to_buckwalter(sentence)

print(f"Original:  {sentence}")
print(f"Buckwalter: {encoded}")