# Installation: pip install shakkala
from shakkala import Shakkala

sh = Shakkala()
# Note: Shakkala often works better if you specify if it's a full sentence
result = sh.vocalize("كيف حالك اليوم؟")
print(result)