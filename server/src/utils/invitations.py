
from utils.db import run_query, get_query_results


def verify_school_invitation_code(invitation_code: str, school_id: int) -> bool:
    """
    Verify if the invitation code is valid for a school 
    """
    # Placeholder for actual verification logic
    # For example, check against a database or a predefined list of valid codes
    valid_codes = {"INVITE123", "WELCOME456", "ACCESS789"}
    return invitation_code in valid_codes

def verify_course_invitation_code(invitation_code: str, course_id: int, author_id: int) -> bool:
    """
    Verify invitation from a course author. This is a placeholder function and should be replaced with actual logic to verify the invitation code against the course and author.
    """
    # Placeholder for actual verification logic
    # For example, check against a database or a predefined list of valid codes
    valid_codes = {"INVITE123", "WELCOME456", "ACCESS789"}
    return invitation_code in valid_codes