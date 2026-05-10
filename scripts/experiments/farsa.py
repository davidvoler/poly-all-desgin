from farasa.diacratizer import FarasaDiacritizer

# Initialize the diacritizer
# This might take a few seconds the first time to load the Java JAR
dg = FarasaDiacritizer()

text = "ذهب الولد إلى المدرسة"
result = dg.diacritize(text)

print(result)