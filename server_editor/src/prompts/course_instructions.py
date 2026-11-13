"""The instructions shared by every AI prompt: written once here and added to each
agent with `instructions=course_instructions()`.

They hold the rules for all prompts (such as no diacritics) and the course author's
guidance (course_options.extra_system_prompt), for example "Literary course: prepare
the student for reading books". use_course sets the course for the length of a
prompt task, so the prompt functions do not have to pass it along.
"""
from contextlib import contextmanager
from contextvars import ContextVar

# Rules for every prompt, course or not.
_RULES = (
    "Write every text, in the learned language and in the student's language, without diacritics "
    "(no vowel marks, such as Arabic harakat or Hebrew niqqud), unless a field explicitly asks for them."
)

_guidance: ContextVar[str | None] = ContextVar("course_guidance", default=None)


@contextmanager
def use_course(guidance: str | None):
    """Sets the course's guidance for the prompts run inside the block."""
    token = _guidance.set((guidance or "").strip() or None)
    try:
        yield
    finally:
        _guidance.reset(token)


def course_instructions() -> str:
    """The shared rules, plus the course author's guidance when the course has some."""
    guidance = _guidance.get()
    if not guidance:
        return _RULES
    return (f"{_RULES}\n\nThe course author's guidance for this course. Follow it in everything you "
            f"write, such as the choice of words, topics, style and register:\n{guidance}")
