from camel_tools.vocalizer.simple import SimpleVocalizer

# 1. Initialize the vocalizer
vocalizer = SimpleVocalizer.pretrained()

# 2. Your test sentence
sentence = "ذهب الولد الى المدرسة"

# 3. Clean and normalize
# clean_text = normalize_alef_maksura_ar(sentence)
# clean_text = dediacritize(clean_text)

# 4. Apply diacritics
vocalized_text = vocalizer.vocalize(sentence)

print(f"Result: {vocalized_text}")