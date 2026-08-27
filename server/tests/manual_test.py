def init_manual_tests():
    import sys, os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../src"))
    print(sys.path)
    os.environ["OLLAMA_HOST"] = "http://localhost:11434"
    os.environ["POSTGRES_CONTENT_PORT"] = "5433"
