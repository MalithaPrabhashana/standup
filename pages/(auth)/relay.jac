"""Relay - the leadership view: bets, what needs you, what is breaking.

Three blocks, read in about thirty seconds, and a quiet screen is the goal.
Nothing here is typed by a human: every line is arithmetic over GitHub
events, so "on track" means something precisely because nobody is able to
say it.

Each line ends in one of four moves - redirect, reassign, unblock, escalate.
Anything that does not lead to one of those is deliberately absent.
"""

import from ...models { RelayThread }
import from ...walkers.relay { RelayThreads }
import from ...components.relay.ThreadRow { ThreadRow }
import from ...components.relay.ThreadTrace { ThreadTrace }
import from ...components.relay.format { humanAge, healthDot, betLabel, betDisplay }
import from ...components.ui.card {
    Card,
    CardHeader,
    CardTitle,
    CardDescription,
    CardContent
}
import from ...components.ui.dialog { Dialog, DialogContent, DialogHeader, DialogTitle }
import from ...components.ui.button { Button }
import from ...components.ui.skeleton { Skeleton }

# A bet is quiet when nothing has been judged on it for this long. Activity is
# easy to fake; a verdict is another person's name on a decision, so tempo is
# measured in verdicts, never in commits.
glob BET_QUIET_HOURS: float = 168.0;


def:pub RelayPage() -> JsxPage {
    has threads: list[RelayThread] = [],
        repo: str = "",
        me: str = "",
        configured: bool = True,
        notice: str = "",
        loading: bool = True,
        openNumber: int = 0;

    async can with entry {
        loadThreads();
    }

    async def loadThreads -> None;
    def showThread(number: int) -> None;

    unowned = [
        t
        for t in threads
        if t.health == "unowned"
    ];
    late = [
        t
        for t in threads
        if t.health == "late"
    ];
    breaking = unowned + late;
    needsYou = [
        t
        for t in threads
        if me and t.holder == me and (t.owed == "validate" or t.health == "late")
    ];

    betNames: list[str] = [];
    for t in threads {
        label = betLabel(t.bet);
        if label not in betNames {
            betNames.append(label);
        }
    }

    selected = [
        t
        for t in threads
        if t.number == openNumber
    ];

    return
        <div className="space-y-8">
            <div className="flex flex-wrap items-end justify-between gap-3">
                <div>
                    <h1 className="font-display text-2xl font-bold tracking-tight">
                        Relay
                    </h1>
                    <p className="text-sm text-muted-foreground">
                        Where the work stands, and what needs a person.
                    </p>
                </div>
                {if repo {
                    <span
                        key="repo"
                        className="rounded-full bg-muted px-3 py-1 font-mono text-xs text-muted-foreground"
                    >
                        {repo}
                    </span>
                }}
            </div>
            {if loading {
                <Skeleton key="sk" className="h-64 w-full"/>
            } elif not configured {
                <Card key="unconf">
                    <CardHeader>
                        <CardTitle className="text-base">Not connected yet</CardTitle>
                        <CardDescription>{notice}</CardDescription>
                    </CardHeader>
                </Card>
            } else {
                <div key="body" className="space-y-6">
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                Bets
                            </CardTitle>
                            <CardDescription>
                                Every thread inherits its why from one of these.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-1">
                            {for name in betNames {
                                <div
                                    key={name}
                                    className="flex items-center gap-3 border-b border-border/60 py-2.5 last:border-0"
                                >
                                    <span
                                        className="h-2 w-2 shrink-0 rounded-full"
                                        style={{
                                            "background": "var(--relay-crit)"
                                                if len(
                                                    [
                                                        t
                                                        for t in unowned
                                                        if betLabel(t.bet) == name
                                                    ]
                                                )
                                                    > 0
                                                else (
                                                    "var(--relay-warn)"
                                                        if len(
                                                            [
                                                                t
                                                                for t in late
                                                                if betLabel(t.bet)
                                                                    == name
                                                            ]
                                                        )
                                                            > 0
                                                        else "var(--relay-good)"
                                                )
                                        }}
                                        aria-hidden="true"
                                    />
                                    <span
                                        className="min-w-0 flex-1 truncate text-sm font-medium"
                                    >
                                        {betDisplay(name)}
                                    </span>
                                    <span
                                        className="shrink-0 text-xs text-muted-foreground"
                                    >
                                        {str(
                                            len(
                                                [
                                                    t
                                                    for t in threads
                                                    if betLabel(t.bet) == name
                                                ]
                                            )
                                        )
                                            + " open"}
                                    </span>
                                    <span
                                        className={"shrink-0 rounded-full px-2 py-0.5 text-[11px] font-semibold "
                                            + (
                                                "text-[var(--relay-crit)] bg-[var(--relay-crit-soft)]"
                                                    if len(
                                                        [
                                                            t
                                                            for t in unowned
                                                            if betLabel(t.bet) == name
                                                        ]
                                                    )
                                                        > 0
                                                    else (
                                                        "text-[var(--relay-warn)] bg-[var(--relay-warn-soft)]"
                                                            if len(
                                                                [
                                                                    t
                                                                    for t in late
                                                                    if betLabel(t.bet)
                                                                        == name
                                                                ]
                                                            )
                                                                > 0
                                                            else "text-[var(--relay-good)] bg-[var(--relay-good-soft)]"
                                                    )
                                            )}
                                    >
                                        {(
                                            str(
                                                len(
                                                    [
                                                        t
                                                        for t in unowned
                                                        if betLabel(t.bet) == name
                                                    ]
                                                )
                                            )
                                            + " unowned"
                                        )
                                            if len(
                                                [
                                                    t
                                                    for t in unowned
                                                    if betLabel(t.bet) == name
                                                ]
                                            )
                                                > 0
                                            else (
                                                (
                                                    str(
                                                        len(
                                                            [
                                                                t
                                                                for t in late
                                                                if betLabel(t.bet)
                                                                    == name
                                                            ]
                                                        )
                                                    )
                                                    + " late"
                                                )
                                                    if len(
                                                        [
                                                            t
                                                            for t in late
                                                            if betLabel(t.bet) == name
                                                        ]
                                                    )
                                                        > 0
                                                    else "on track"
                                            )}
                                    </span>
                                </div>
                            }}
                            {if len(betNames) == 0 {
                                <p
                                    key="nobets"
                                    className="py-2 text-sm text-muted-foreground"
                                >
                                    No open threads.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                {"Needs you · " + str(len(needsYou))}
                            </CardTitle>
                            <CardDescription>
                                Only what nobody else is allowed to sign.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-0.5">
                            {for t in needsYou {
                                <ThreadRow
                                    key={str(t.number)}
                                    thread={t}
                                    onOpen={showThread}
                                />
                            }}
                            {if len(needsYou) == 0 {
                                <p
                                    key="clear"
                                    className="py-2 text-sm text-muted-foreground"
                                >
                                    Nothing is waiting on you. That is the normal state.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                {"Breaking · " + str(len(breaking))}
                            </CardTitle>
                            <CardDescription>
                                Work nobody is holding, and batons held past their clock.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-0.5">
                            {for t in breaking {
                                <ThreadRow
                                    key={str(t.number)}
                                    thread={t}
                                    onOpen={showThread}
                                />
                            }}
                            {if len(breaking) == 0 {
                                <p
                                    key="quiet"
                                    className="py-2 text-sm text-muted-foreground"
                                >
                                    Nothing is stuck. Close the tab.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                </div>
            }  }
            <Dialog
                open={openNumber > 0}
                onOpenChange={lambda (v: bool) { showThread(0) if not v else None; }}
            >
                <DialogContent className="sm:max-w-2xl">
                    <DialogHeader>
                        <DialogTitle className="pr-6 text-base leading-snug">
                            {selected[0].title if len(selected) > 0 else ""}
                        </DialogTitle>
                    </DialogHeader>
                    {if len(selected) > 0 {
                        <ThreadTrace key="trace" thread={selected[0]}/>
                    }}
                    {if len(selected) > 0 and selected[0].url {
                        <a
                            key="link"
                            href={selected[0].url}
                            target="_blank"
                            rel="noreferrer"
                            className="text-xs font-medium text-primary underline underline-offset-4"
                        >
                            Open on GitHub
                        </a>
                    }}
                </DialogContent>
            </Dialog>
        </div>;
}
