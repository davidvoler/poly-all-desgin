from models.exercise import Exercise


def test_exercise_accepts_option_objects():
    exercise = Exercise(
        answer="We heard him come downstairs.",
        options=[
            {"text": "Tobias rushed down the stairs."},
            {"text": "We started according to plan."},
            {"text": "We heard him come downstairs.", "correct": True},
        ],
    )

    assert exercise.model_dump(mode="json")["options"] == [
        {"text": "Tobias rushed down the stairs.", "correct": False},
        {"text": "We started according to plan.", "correct": False},
        {"text": "We heard him come downstairs.", "correct": True},
    ]

