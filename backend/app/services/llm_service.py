import json
import logging
import re
from typing import Any

from app.config import get_settings

logger = logging.getLogger(__name__)

_SYSTEM_CONTEXT = (
    "Tomoni 일본어 경어 학습 앱의 AI 대화 파트너. "
    "지정된 역할·장소·관계에 완전히 몰입해 자연스러운 일본어 구어체로 대화한다. "
    "교과서式 문장, 같은 표현 반복, 설명조, 사용자 발화 무시, 엉뚱한 답변은 금지. "
    "JSON만 출력. "
    "text=일본어만. "
    "pronunciation=해당 일본어의 한글 발음(가-힣만, romaji·영문·일본어 금지). "
    "translation=해당 일본어의 한국어 뜻(가-힣만, 일본어·영문 금지, 원문 복사 금지)."
)


def _extract_json(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", cleaned, re.DOTALL)
        if match:
            return json.loads(match.group())
        raise


def _generate_with_gemini(prompt: str, temperature: float) -> dict[str, Any]:
    settings = get_settings()
    from google import genai

    client = genai.Client(api_key=settings.gemini_api_key)
    response = client.models.generate_content(
        model=settings.gemini_model,
        contents=f"{_SYSTEM_CONTEXT}\n\n{prompt}",
        config={
            "response_mime_type": "application/json",
            "temperature": temperature,
        },
    )
    return _extract_json(response.text or "{}")


def _generate_with_openai(prompt: str, temperature: float) -> dict[str, Any]:
    settings = get_settings()
    from openai import OpenAI

    client = OpenAI(api_key=settings.openai_api_key)
    response = client.chat.completions.create(
        model=settings.openai_chat_model,
        messages=[
            {"role": "system", "content": _SYSTEM_CONTEXT},
            {"role": "user", "content": prompt},
        ],
        response_format={"type": "json_object"},
        temperature=temperature,
    )
    content = response.choices[0].message.content or "{}"
    return _extract_json(content)


def generate_json(prompt: str, *, temperature: float = 0.85) -> dict[str, Any]:
    settings = get_settings()
    provider = settings.dialogue_provider

    if provider == "openai":
        if not settings.openai_enabled:
            raise RuntimeError("OpenAI API key is not configured")
        logger.debug("LLM request via OpenAI (%s)", settings.openai_chat_model)
        return _generate_with_openai(prompt, temperature)

    if not settings.gemini_enabled:
        raise RuntimeError("Gemini API key is not configured")
    logger.debug("LLM request via Gemini (%s)", settings.gemini_model)
    return _generate_with_gemini(prompt, temperature)


def try_generate_json(
    prompt: str, *, temperature: float = 0.85
) -> dict[str, Any] | None:
    settings = get_settings()
    providers: list[str] = []

    if settings.dialogue_provider == "openai":
        providers = ["openai", "gemini"] if settings.gemini_enabled else ["openai"]
    else:
        providers = ["gemini", "openai"] if settings.openai_enabled else ["gemini"]

    for provider in providers:
        try:
            if provider == "openai":
                if not settings.openai_enabled:
                    continue
                return _generate_with_openai(prompt, temperature)
            if not settings.gemini_enabled:
                continue
            return _generate_with_gemini(prompt, temperature)
        except Exception as exc:
            logger.warning("%s dialogue call failed: %s", provider, exc)
    return None
