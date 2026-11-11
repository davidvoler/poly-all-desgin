from pydantic import BaseModel, Field
from babel import Locale
from babel.core import UnknownLocaleError
from models.language import Language



# Top 100 most common languages (ordered by speaker count / global prevalence)
COMMON_LANGUAGES = [
    "en", "zh", "hi", "es", "fr", "ar", "bn", "ru", "pt", "id",
    "ur", "de", "ja", "sw", "mr", "te", "tr", "ta", "yue", "vi",
    "tl", "ko", "fa", "ha", "jv", "it", "pa", "kn", "gu", "th",
    "uk", "nl", "pl", "ro", "az", "hu", "el", "cs", "sv", "he",
    "da", "fi", "no", "sk", "sl", "bg", "hr", "sr", "lt", "lv",
    "et", "mt", "is", "ga", "sq", "mk", "bs", "kk", "uz", "ky",
    "tg", "tk", "hy", "ka", "mn", "my", "km", "lo", "ne", "si",
    "am", "so", "om", "ig", "yo", "zu", "xh", "af", "mg", "sn",
    "ny", "st", "tn", "ss", "nr", "ts", "ve", "ti", "rw", "rn",
    "lg", "ak", "bm", "ff", "ln", "wo", "eu", "gl", "ca", "cy"
]

def get_top_languages(request_locale: str = "en") -> list[Language]:
    # 1. Target locale requested by user (fallback to 'en')
    try:
        target_loc = Locale.parse(request_locale)
    except (UnknownLocaleError, ValueError):
        target_loc = Locale.parse("en")

    result = []
    total_count = len(COMMON_LANGUAGES)

    for index, code in enumerate(COMMON_LANGUAGES):
        # 2. Translated name (e.g. "Hebrew" -> "עברית" when request is 'he')
        translated_name = target_loc.languages.get(code) or code
        
        # 3. Native name (language name in itself)
        try:
            native_loc = Locale.parse(code)
            native_name = native_loc.get_language_name(code) or translated_name
        except (UnknownLocaleError, ValueError):
            native_name = translated_name

        # Weight goes from 100 down to 1
        weight = total_count - index

        result.append(
            Language(
                code=code,
                name=translated_name.capitalize(),
                native_name=native_name.capitalize(),
                weight=weight
            )
        )

    return result
