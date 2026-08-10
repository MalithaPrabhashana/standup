"""Flow - the lead's view: where work is jammed, and who is carrying it.

Three blocks with three different scopes, said out loud so nobody has to
guess: Load is one row per person, Board is every open thread grouped by
what is owed, and Routes is the rulebook with no work on it at all.

There is nothing to drag here. A card moves because a claim was made or a
verdict was signed on GitHub, so the lead's job stops being bookkeeping and
becomes unjamming: unowned work first, breached batons second.
"""

import from ...models { RelayThread }
import from ...walkers.relay { RelayThreads }
import from ...components.relay.ThreadRow { ThreadRow }
import from ...components.relay.ThreadTrace { ThreadTrace }
import from ...components.relay.format { humanAge, healthDot, initials }
import from ...components.ui.card {
    Card,
    CardHeader,
    CardTitle,
    CardDescription,
    CardContent
}
import from ...components.ui.dialog { Dialog, DialogContent, DialogHeader, DialogTitle }
import from ...components.ui.skeleton { Skeleton }

glob VERBS: list[str] = ["build", "judge", "validate"];
glob VERB_TITLE: dict[str, str] = {
         "build": "BEING BUILT",
         "judge": "AWAITING JUDGMENT",
         "validate": "AWAITING VALIDATION"
     };

# The routes, drawn once. Kind picks the route; gates add signatures.
glob ROUTE_ROWS: list[dict[str, str]] = [
         {"kind": "BUG", "steps": "Build → Judge → Validate, by whoever reported it"},
         {"kind": "FEATURE", "steps": "Build → Judge, by the surface owner → Validate"},
         {"kind": "ARCH", "steps": "Build → Domain review → Arch review → Validate"}
     ];


def:pub FlowPage() -> JsxPage {
    has threads: list[RelayThread] = [],
        repo: str = "",
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

    holders: list[str] = [];
    for t in threads {
        if t.holder and t.holder not in holders {
            holders.append(t.holder);
        }
    }

    # Peak load, computed with an explicit loop: max() over a list compiles
    # to Math.max(array), which is NaN.
    peak = 1;
    for who in holders {
        held = len(
            [
                t
                for t in threads
                if t.holder == who
            ]
        );
        if held > peak {
            peak = held;
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
                        Flow
                    </h1>
                    <p className="text-sm text-muted-foreground">
                        Live from GitHub. Nothing on this page is typed by hand.
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
                    <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                        <div
                            className="rounded-xl border border-border bg-muted/40 p-4"
                        >
                            <div
                                className="text-2xl font-bold tabular-nums"
                                style={{
                                    "color": "var(--relay-crit)"
                                        if len(unowned) > 0
                                        else "inherit"
                                }}
                            >
                                {str(len(unowned))}
                            </div>
                            <div className="mt-0.5 text-xs text-muted-foreground">
                                threads with no holder
                            </div>
                        </div>
                        <div
                            className="rounded-xl border border-border bg-muted/40 p-4"
                        >
                            <div
                                className="text-2xl font-bold tabular-nums"
                                style={{
                                    "color": "var(--relay-warn)"
                                        if len(late) > 0
                                        else "inherit"
                                }}
                            >
                                {str(len(late))}
                            </div>
                            <div className="mt-0.5 text-xs text-muted-foreground">
                                batons past their clock
                            </div>
                        </div>
                        <div
                            className="rounded-xl border border-border bg-muted/40 p-4"
                        >
                            <div className="text-2xl font-bold tabular-nums">
                                {str(len(threads))}
                            </div>
                            <div className="mt-0.5 text-xs text-muted-foreground">
                                open threads in total
                            </div>
                        </div>
                    </div>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                Load · batons held now
                            </CardTitle>
                            <CardDescription>
                                One row per person. Red segments are past the clock.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-2.5">
                            {for who in holders {
                                <div key={who} className="flex items-center gap-3">
                                    <span
                                        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/10 text-[10px] font-bold text-primary"
                                    >
                                        {initials(who)}
                                    </span>
                                    <span className="w-40 shrink-0 truncate text-sm">
                                        {who}
                                    </span>
                                    <span className="flex flex-1 items-center gap-1">
                                        {for t in [
                                            x
                                            for x in threads
                                            if x.holder == who
                                        ] {
                                            <span
                                                key={str(t.number)}
                                                className="h-3 w-10 rounded"
                                                style={{
                                                    "background": healthDot(t.health)
                                                }}
                                                title={t.title}
                                            />
                                        }}
                                    </span>
                                    <span
                                        className="w-28 shrink-0 text-right text-xs text-muted-foreground"
                                    >
                                        {str(
                                            len(
                                                [
                                                    x
                                                    for x in threads
                                                    if x.holder == who
                                                ]
                                            )
                                        )
                                            + " held"}
                                    </span>
                                </div>
                            }}
                            {if len(holders) == 0 {
                                <p
                                    key="nobody"
                                    className="text-sm text-muted-foreground"
                                >
                                    Nobody is holding anything. Every open thread is unowned.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                Board · grouped by what is owed
                            </CardTitle>
                            <CardDescription>
                                Every open thread in this repo, all people. Nothing to drag.
                            </CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
                                {for verb in VERBS {
                                    <div
                                        key={verb}
                                        className="rounded-xl bg-muted/40 p-3"
                                    >
                                        <div
                                            className="flex items-baseline justify-between"
                                        >
                                            <span
                                                className="font-mono text-[10px] font-bold tracking-wider text-muted-foreground"
                                            >
                                                {VERB_TITLE[verb]}
                                            </span>
                                            <span
                                                className="text-sm font-bold tabular-nums"
                                            >
                                                {str(
                                                    len(
                                                        [
                                                            t
                                                            for t in threads
                                                            if t.owed == verb
                                                        ]
                                                    )
                                                )}
                                            </span>
                                        </div>
                                        <div className="mt-2 space-y-1">
                                            {for t in [
                                                x
                                                for x in threads
                                                if x.owed == verb
                                            ] {
                                                <ThreadRow
                                                    key={str(t.number)}
                                                    thread={t}
                                                    onOpen={showThread}
                                                    showBet={False}
                                                />
                                            }}
                                            {if len(
                                                [
                                                    t
                                                    for t in threads
                                                    if t.owed == verb
                                                ]
                                            )
                                                == 0 {
                                                <p
                                                    key="none"
                                                    className="px-3 py-2 text-xs text-muted-foreground"
                                                >
                                                    Nothing here.
                                                </p>
                                            }}
                                        </div>
                                    </div>
                                }}
                            </div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                Routes · one per kind of work, drawn once
                            </CardTitle>
                            <CardDescription>
                                No tasks here. This is the rulebook every thread obeys.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-0">
                            {for row in ROUTE_ROWS {
                                <div
                                    key={row["kind"]}
                                    className="flex flex-wrap items-center gap-3 border-b border-border/60 py-3 last:border-0"
                                >
                                    <span
                                        className="w-20 shrink-0 font-mono text-[10px] font-bold tracking-wider text-muted-foreground"
                                    >
                                        {row["kind"]}
                                    </span>
                                    <span className="text-sm text-foreground">
                                        {row["steps"]}
                                    </span>
                                </div>
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
                </DialogContent>
            </Dialog>
        </div>;
}
