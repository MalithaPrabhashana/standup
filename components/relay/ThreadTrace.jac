"""One thread traced across its route: the only graph drawn with real work on it.

A board column says "In Review" for nine days and nothing more. This says
where the work is, who has held it, how long, and what is owed next, because
the route is a chain of claims and verdicts rather than a set of buckets.

The route is chosen by the thread's kind, so a typo fix does not walk the
same path as an architecture change. Position is DERIVED from GitHub events,
never stored, which is why nobody has to drag anything to keep it true.
"""

import from ...models { RelayThread }
import from .format { humanAge, humanClock, healthDot }

# The routes. Each kind of work collects a different number of signatures,
# but every route is the same spine: build, then judge, then validate.
glob ROUTES: dict[str, list[str]] = {
         "bug": ["Implementing", "Awaiting review", "Awaiting validation"],
         "feature": ["Implementing", "Awaiting review", "Awaiting validation"],
         "arch": ["Implementing", "Awaiting review", "Awaiting validation"]
     };

glob STEP_CLAIM: dict[str, str] = {
         "Implementing": "\"the code is written\"",
         "Awaiting review": "approved, merged",
         "Awaiting validation": "confirmed fixed"
     };

# Who signs the verdict at each hand-off, as a role rather than a name. The
# role resolves to a person per thread, which is what lets the same route
# serve every piece of work.
glob STEP_JUDGE: dict[str, str] = {
         "Implementing": "reviewer",
         "Awaiting review": "reviewer",
         "Awaiting validation": "whoever raised it"
     };


def routeFor(kind: str) -> list[str] {
    if kind in ROUTES {
        return ROUTES[kind];
    }
    return ROUTES["bug"];
}


# Where the thread sits on its route. "Unassigned" means it has not entered
# the route at all, which is a state a board cannot express.
def stepIndex(route: list[str], stage: str) -> int {
    idx = 0;
    for name in route {
        if name == stage {
            return idx;
        }
        idx = idx + 1;
    }
    return -1;
}


def:pub ThreadTrace(thread: RelayThread) -> JsxElement {
    route = routeFor(thread.kind);
    current = stepIndex(route, thread.stage);
    holderName = thread.holder if thread.holder else "nobody";

    return
        <div className="space-y-5">
            <div className="flex flex-wrap items-center gap-2">
                <span
                    className="rounded-full bg-[var(--relay-accent-soft)] px-2.5 py-1 text-[11px] font-semibold text-[var(--relay-accent)]"
                >
                    {"kind:" + (thread.kind if thread.kind else "unclassified")}
                </span>
                <span
                    className="rounded-full bg-muted px-2.5 py-1 text-[11px] text-muted-foreground"
                >
                    {"bet: " + (thread.bet if thread.bet else "none declared")}
                </span>
                {if thread.pr_number > 0 {
                    <span
                        key="pr"
                        className="rounded-full bg-muted px-2.5 py-1 font-mono text-[11px] text-muted-foreground"
                    >
                        {"PR #" + str(thread.pr_number) + " " + thread.pr_state}
                    </span>
                }}
            </div>
            <div className="overflow-x-auto pb-2">
                <div className="flex min-w-[560px] items-start">
                    {for i in range(len(route)) {
                        <div key={route[i]} className="flex flex-1 items-start">
                            <div
                                className="flex w-full flex-col items-center gap-1 text-center"
                            >
                                <span
                                    className="mb-1 grid h-4 w-4 place-items-center rounded-full border-2"
                                    style={{
                                        "background": healthDot(thread.health)
                                            if i == current
                                            else (
                                                "var(--relay-good)"
                                                    if current >= 0 and i < current
                                                    else "var(--background)"
                                            ),
                                        "borderColor": healthDot(thread.health)
                                            if i == current
                                            else (
                                                "var(--relay-good)"
                                                    if current >= 0 and i < current
                                                    else "var(--border)"
                                            )
                                    }}
                                    aria-hidden="true"
                                />
                                <span
                                    className={"text-xs font-semibold "
                                        + (
                                            "text-foreground"
                                                if i <= current and current >= 0
                                                else "text-muted-foreground"
                                        )}
                                >
                                    {route[i]}
                                </span>
                                <span className="text-[11px] text-muted-foreground">
                                    {holderName
                                        if i == current
                                        else STEP_JUDGE[route[i]]}
                                </span>
                                {if i == current {
                                    <span
                                        key="now"
                                        className="mt-0.5 rounded px-1.5 py-0.5 font-mono text-[9px] font-bold tracking-wider"
                                        style={{
                                            "color": healthDot(thread.health),
                                            "background": "var(--muted)"
                                        }}
                                    >
                                        {"HELD "
                                            + humanAge(thread.age_hours)
                                            + " OF "
                                            + humanClock(thread.clock_hours)}
                                    </span>
                                }}
                            </div>
                            {if i < len(route) - 1 {
                                <div
                                    key="conn"
                                    className="mt-2 flex w-24 shrink-0 flex-col items-center px-2"
                                >
                                    <div
                                        className="h-0.5 w-full rounded"
                                        style={{
                                            "background": "var(--relay-good)"
                                                if current >= 0 and i < current
                                                else "var(--border)"
                                        }}
                                    />
                                    <span
                                        className="mt-2 whitespace-nowrap text-center text-[10px] leading-tight text-muted-foreground"
                                    >
                                        {STEP_CLAIM[route[i]]}
                                    </span>
                                </div>
                            }}
                        </div>
                    }}
                </div>
            </div>
            <div
                className="rounded-lg border border-dashed border-border bg-muted/40 p-3"
            >
                <p
                    className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
                >
                    Why it says that
                </p>
                <p className="mt-1 text-sm text-foreground">{thread.why}</p>
                {if current < 0 {
                    <p key="off" className="mt-2 text-xs text-muted-foreground">
                        This thread has not entered its route yet: nobody has started it.
                    </p>
                }}
            </div>
        </div>;
}
