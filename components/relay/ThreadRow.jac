"""One thread, rendered as a sentence rather than a card on a board.

A column tells you where work sits. This tells you who it waits on and for
how long, which is the only thing anyone can act on. Clicking it opens the
trace, so every summary can be audited down to its arithmetic.
"""

import from ...models { RelayThread }
import from .format {
    humanAge,
    humanClock,
    waitingSentence,
    healthTone,
    healthDot,
    owedTone,
    betDisplay,
    OWED_LABEL,
    HEALTH_LABEL
}

def:pub ThreadRow(
    thread: RelayThread, onOpen: Callable[[int], None] = None, showBet: bool = True
) -> JsxElement {
    holderName = thread.holder if thread.holder else "nobody";
    # A clock only runs against a person. Unowned work has nobody to be late,
    # so it shows how long it has drifted, never "of <clock>".
    showClock = thread.health == "late";

    return
        <button
            type="button"
            onClick={lambda() { onOpen(thread.number) if onOpen else None; }}
            className="group flex w-full items-center gap-3 rounded-lg border border-transparent px-3 py-2.5 text-left transition-colors hover:border-border hover:bg-muted/50"
        >
            <span
                className="h-2 w-2 shrink-0 rounded-full"
                style={{"background": healthDot(thread.health)}}
                aria-hidden="true"
            />
            <span
                className={"shrink-0 rounded px-1.5 py-0.5 font-mono text-[10px] font-bold tracking-wider "
                    + owedTone(thread.owed)}
            >
                {OWED_LABEL[thread.owed] if thread.owed in OWED_LABEL else "BUILD"}
            </span>
            <span className="min-w-0 flex-1">
                <span className="block truncate text-sm font-medium text-foreground">
                    {thread.title}
                </span>
                <span className="mt-0.5 block truncate text-xs text-muted-foreground">
                    {waitingSentence(thread.holder, thread.owed, thread.age_hours)}
                </span>
            </span>
            {if showBet and thread.bet {
                <span
                    key="bet"
                    className="hidden shrink-0 rounded-full bg-muted px-2 py-0.5 text-[11px] text-muted-foreground sm:inline"
                >
                    {betDisplay(thread.bet)}
                </span>
            }}
            <span
                className={"shrink-0 rounded-full px-2 py-0.5 text-[11px] font-semibold "
                    + healthTone(thread.health)}
            >
                {("nobody · " + humanAge(thread.age_hours))
                    if thread.health == "unowned"
                    else (
                        humanAge(thread.age_hours)
                        + (" of " + humanClock(thread.clock_hours) if showClock else "")
                    )}
            </span>
            <span className="shrink-0 font-mono text-[11px] text-muted-foreground">
                {"#" + str(thread.number)}
            </span>
        </button>;
}
