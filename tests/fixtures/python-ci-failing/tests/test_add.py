from fixture import add


def test_add_fails() -> None:
    # Fails on purpose: python-ci must report it.
    assert add(1, 2) == 4
