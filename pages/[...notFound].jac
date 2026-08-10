"""Catch-all for URLs that no longer exist.

The daily Log and the Overview page were removed when work stopped being
something people type and became something derived, so old bookmarks land
here. A blank screen is the worst possible answer to a stale link: say what
happened, then offer the one page that replaced it.
"""

import from ..components.ui.button { Button }

def:pub NotFoundPage() -> JsxPage {
    return
        <div
            className="mx-auto flex max-w-md flex-col items-center gap-4 py-24 text-center"
        >
            <p
                className="font-mono text-xs font-bold uppercase tracking-[0.14em] text-muted-foreground"
            >
                404
            </p>
            <h1 className="font-display text-2xl font-bold tracking-tight">
                Nothing lives at this address
            </h1>
            <p className="text-sm text-muted-foreground">
                The daily log and the overview were removed. Status is no longer written down by anyone: it is derived from the work itself, and it lives on Relay.
            </p>
            <a href="/relay">
                <Button>Go to Relay</Button>
            </a>
        </div>;
}
