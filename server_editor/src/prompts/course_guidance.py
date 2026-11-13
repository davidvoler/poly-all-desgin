"""The course author's guidance, added to every AI prompt for the course.

The author writes it on the course (course_options.extra_system_prompt), for example
"Literary course: prepare the student for reading books" or "Day-to-day spoken
sentences". use_course_guidance sets it for the length of a prompt task, so the
prompt functions do not have to pass it along.
"""
from contextlib import contextmanager
from contextvars import ContextVar

_guidance: ContextVar[str | None] = ContextVar("course_guidance", default=None)


@contextmanager
def use_course_guidance(text: str | None):
    token = _guidance.set((text or "").strip() or None)
    try:
        yield
    finally:
        _guidance.reset(token)


def course_guidance() -> str | None:
    """The instructions to add to an agent, or None when the course has no guidance."""
    text = _guidance.get()
    if not text:
        return None
    return ("The course author's guidance for this course. Follow it in everything you write, "
            f"such as the choice of words, topics, style and register:\n{text}")
