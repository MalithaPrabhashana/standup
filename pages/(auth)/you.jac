"""You - one person's batons, and the delays that are provably not theirs.

The order of the blocks is the whole argument for adopting this. "In your
hands" comes first because it is the only list you must act on. "Waiting on
others" comes second, and it is the block that wins the room: when you did
your part in a day and it then sat in review for nine, the nine days are
visibly somebody else's.

A screen that only exposes gets quietly sabotaged. A screen that visibly
protects gets adopted. So this one does both, in that order.
"""

import from ...models { RelayThread }
import from ...walkers.relay { RelayThreads }
import from ...components.relay.ThreadRow { ThreadRow }
import from ...components.relay.ThreadTrace { ThreadTrace }
import from ...components.relay.format { initials }
import from ...components.ui.card {
    Card,
    CardHeader,
    CardTitle,
    CardDescription,
    CardContent
}
import from ...components.ui.dialog { Dialog, DialogContent, DialogHeader, DialogTitle }
import from ...components.ui.select {
    Select,
    SelectTrigger,
    SelectValue,
    SelectContent,
    SelectItem
}
import from ...components.ui.skeleton { Skeleton }


def:pub YouPage() -> JsxPage {
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
    def pickPerson(who: str) -> None;

    people: list[str] = [];
    for t in threads {
        if t.holder and t.holder not in people {
            people.append(t.holder);
        }
    }

    mine = [
        t
        for t in threads
        if me and t.holder == me
    ];
    # Raised by me but now in somebody else's hands. Derived from the
    # validator rule: a bug returns to whoever reported it, so a thread whose
    # validation would land on me is mine to care about, not to act on.
    elsewhere = [
        t
        for t in threads
        if me and t.holder != me and t.owed != "validate" and t.kind == "bug"
    ];
    incoming = [
        t
        for t in threads
        if me and t.holder != me and t.owed == "judge"
    ];

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
                        {me if me else "You"}
                    </h1>
                    <p className="text-sm text-muted-foreground">
                        If it is not on this screen, nothing is waiting on you.
                    </p>
                </div>
                {if len(people) > 0 {
                    <Select key="who" value={me} onValueChange={pickPerson}>
                        <SelectTrigger className="w-56">
                            <SelectValue placeholder="Who are you?"/>
                        </SelectTrigger>
                        <SelectContent>
                            {for who in people {
                                <SelectItem key={who} value={who}>{who}</SelectItem>
                            }}
                        </SelectContent>
                    </Select>
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
                                {"In your hands · " + str(len(mine))}
                            </CardTitle>
                            <CardDescription>
                                Hold them briefly, pass them cleanly.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-0.5">
                            {for t in mine {
                                <ThreadRow
                                    key={str(t.number)}
                                    thread={t}
                                    onOpen={showThread}
                                />
                            }}
                            {if len(mine) == 0 {
                                <p
                                    key="clear"
                                    className="py-2 text-sm text-muted-foreground"
                                >
                                    Nothing is in your hands right now.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                {"Waiting on others · " + str(len(incoming))}
                            </CardTitle>
                            <CardDescription>
                                Time spent here is visibly not your delay.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-0.5">
                            {for t in incoming {
                                <ThreadRow
                                    key={str(t.number)}
                                    thread={t}
                                    onOpen={showThread}
                                />
                            }}
                            {if len(incoming) == 0 {
                                <p
                                    key="none"
                                    className="py-2 text-sm text-muted-foreground"
                                >
                                    Nothing of yours is sitting with someone else.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardTitle
                                className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground"
                            >
                                {"Coming back to you · " + str(len(elsewhere))}
                            </CardTitle>
                            <CardDescription>
                                Bugs return to whoever reported them when the fix merges. Nobody has to remember.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-0.5">
                            {for t in elsewhere {
                                <ThreadRow
                                    key={str(t.number)}
                                    thread={t}
                                    onOpen={showThread}
                                />
                            }}
                            {if len(elsewhere) == 0 {
                                <p
                                    key="none"
                                    className="py-2 text-sm text-muted-foreground"
                                >
                                    Nothing is on its way back to you.
                                </p>
                            }}
                        </CardContent>
                    </Card>
                    <p
                        className="border-t border-dashed border-border pt-4 text-xs italic text-muted-foreground"
                    >
                        No standup, no daily log. Nobody will ask you for status, because this page already knows.
                    </p>
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
