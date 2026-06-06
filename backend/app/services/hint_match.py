import re


def normalize_japanese_text(text: str) -> str:
    cleaned = str(text or "").strip()
    cleaned = re.sub(r"[\s　。、！？!?.,，「」『』（）()\"'\"\"''\[\]{}]", "", cleaned)
    return cleaned.lower()


def texts_match_hint(user_text: str, hint_text: str) -> bool:
    user = normalize_japanese_text(user_text)
    hint = normalize_japanese_text(hint_text)
    if not user or not hint:
        return False
    if user == hint:
        return True
    if len(hint) >= 4 and (hint in user or user in hint):
        return True
    shorter, longer = (user, hint) if len(user) <= len(hint) else (hint, user)
    if len(shorter) >= 6 and shorter in longer:
        return True
    return False
