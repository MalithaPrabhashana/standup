"""Implementations for the personal Relay page."""

impl YouPage.loadThreads -> None {
    try {
        result = root spawn RelayThreads();
        payload = result.reports[0] if result.reports else {};
        threads = payload["threads"] if payload else [];
        repo = payload["repo"] if payload else "";
        configured = payload["configured"] if payload else False;
        notice = payload["message"] if payload else "";
        # RELAY_ME is the default, but the picker wins once someone chooses,
        # so the screen is useful before any per-user config exists.
        if not me {
            me = payload["me"] if payload else "";
        }
    } except Exception as e {
        configured = False;
        notice = "Could not read GitHub. Check GITHUB_TOKEN and RELAY_REPO.";
    }
    loading = False;
}


impl YouPage.showThread(number: int) -> None {
    openNumber = number;
}


impl YouPage.pickPerson(who: str) -> None {
    me = who;
}
