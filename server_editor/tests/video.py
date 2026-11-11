'''
Test cases for video-related functionality.
'''
import pytest

from models.video import Video
def test_video_creation():
    video = Video(title="Test Video", description="This is a test video.")
    assert video.title == "Test Video"
    assert video.description == "This is a test video."
