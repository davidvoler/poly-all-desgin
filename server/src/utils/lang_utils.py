import pycountry

def get_language_name(code: str) -> str:
    """Translates ISO 639-1 ('en', 'fr') or ISO 639-2 ('eng', 'fra') code to full language name."""
    lang = pycountry.languages.get(alpha_2=code.lower()) or pycountry.languages.get(alpha_3=code.lower())
    return lang.name if lang else code