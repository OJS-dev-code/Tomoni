from typing import Any

GOAL_COMPLETION_RULES = """
[목표 달성 판정 — 학습자에게 관대하게]
- 완벽한 일본어·정확한 경어·목표 문구와의 일치를 요구하지 말 것.
- 사용자 발화의 **의도·맥락**이 목표와 맞으면 달성으로 본다.
- 비슷한 뜻, 다른 표현, 간접적 말하기, 약간의 실수도 인정한다.
- 목표가 "○○하기"이면, 그 행동을 **시도하거나** 관련 요청·질문·응답을 했으면 충분하다.
- AI가 해당 요청을 이해하고 응대했다면, 사용자 쪽 목표는 달성으로 볼 수 있다.
- 한 턴에 여러 목표를 동시에 달성할 수 있다.
- 이미 달성한 목표는 newlyCompletedGoalIndices에 넣지 않는다.
- newlyCompletedGoalIndices: 이번 턴에 **새로** 달성한 목표 인덱스만 (정수 배열).
- allGoalsCompleted: 남은 목표가 없으면 true.
"""


def normalize_goal_completion(
    data: dict[str, Any],
    goals: list[str],
    completed_indices: list[int],
) -> dict[str, Any]:
    """LLM 목표 판정 결과를 정리하고, allGoalsCompleted와 인덱스를 일치시킨다."""
    if not goals:
        data["newlyCompletedGoalIndices"] = []
        data["allGoalsCompleted"] = True
        return data

    completed_set = set(completed_indices)
    newly: list[int] = []

    for raw in data.get("newlyCompletedGoalIndices") or []:
        try:
            idx = int(raw)
        except (TypeError, ValueError):
            continue
        if 0 <= idx < len(goals) and idx not in completed_set:
            newly.append(idx)

    if data.get("allGoalsCompleted"):
        for idx in range(len(goals)):
            if idx not in completed_set and idx not in newly:
                newly.append(idx)

    merged = sorted(completed_set | set(newly))
    data["newlyCompletedGoalIndices"] = sorted(set(newly))
    data["allGoalsCompleted"] = len(merged) == len(goals)
    return data


def build_lenient_goal_eval_prompt(
    *,
    goals: list[str],
    completed_indices: list[int],
    user_text: str,
    ai_message: dict[str, Any],
    history: list[dict[str, Any]],
) -> str:
    goals_block = "\n".join(f"{i}: {goal}" for i, goal in enumerate(goals))
    remaining = [i for i in range(len(goals)) if i not in completed_indices]
    ai_text = str(ai_message.get("text", ""))
    ai_trans = str(ai_message.get("translation", ""))

    recent_user = [
        str(item.get("text", ""))
        for item in history
        if not item.get("isAI") and item.get("text")
    ][-3:]
    recent_block = "\n".join(f"- {line}" for line in recent_user) if recent_user else "(없음)"

    return f"""일본어 학습 역할극의 목표 달성 여부만 **관대하게** 판정한다.
{GOAL_COMPLETION_RULES}

목표(인덱스):
{goals_block}

이미 달성: {sorted(completed_indices)}
아직 남음: {remaining}

최근 사용자 발화:
{recent_block}

이번 사용자 발화: {user_text}
AI 응답(일본어): {ai_text}
AI 응답(한국어): {ai_trans}

위 맥락에서 이번 턴에 새로 달성한 목표 인덱스만 골라라. 애매하면 학습자에게 유리하게 달성 처리해도 된다.

JSON:
{{
  "newlyCompletedGoalIndices": []
}}"""
