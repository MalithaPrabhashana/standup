"""Implementations for the Relay leadership page."""

impl RelayPage.loadThreads -> None {
    try {
        result = root spawn RelayThreads();
        payload = result.reports[0] if result.reports else {};
        threads = payload["threads"] if payload else [];
        repo = payload["repo"] if payload else "";
        me = payload["me"] if payload else "";
        configured = payload["configured"] if payload else False;
        notice = payload["message"] if payload else "";
    } except Exception as e {
        configured = False;
        notice = "Could not read GitHub. Check GITHUB_TOKEN and RELAY_REPO.";
    }
    loading = False;
}


impl RelayPage.showThread(number: int) -> None {
    openNumber = number;
}
