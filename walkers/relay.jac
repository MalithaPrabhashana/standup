"""Relay: derive the state of work from GitHub, and never store it.

The whole model in one module. Every thread answers the same five questions
at all times:

    1. Why does it exist?      -> the bet it serves          (declared, a label)
    2. Whose hands is it in?   -> exactly one holder         (derived)
    3. What do they owe?       -> build / judge / validate   (derived)
    4. How long have they held it?                           (derived)
    5. Who says it is done?    -> the kind fixes the judge   (declared, a label)

Only questions 1 and 5 are declared, once, by putting two labels on a GitHub
issue. Everything else is arithmetic over GitHub events, recomputed on every
read. That is the point: a fact nobody maintains is a fact that cannot rot,
so this module deliberately has no writes, no cache and no Sync button.

A holder of "" is NOT a state, it is an incident: work nobody is holding is
the thing a board structurally cannot show you.

Server-only, so Python imports are fine here (models.jac must stay clean).
"""

import os;
import re;
import datetime;

import from models { RelayThread }
import from walkers.ghutil { gh_request }

# GitHub caps a page at 100; one page is plenty for a workspace and keeps the
# request count at two regardless of repo size.
glob RELAY_PAGE: int = 100;

# Clocks are POLICY, not data: how long it is acceptable for work to sit in
# one pair of hands. Declared once, tuned rarely, overridable from the
# environment so a demo can use minutes where a team uses days.
glob CLOCK_BUILD: float = 24.0;
glob CLOCK_JUDGE: float = 48.0;
glob CLOCK_VALIDATE: float = 72.0;

glob OWED_BUILD: str = "build";
glob OWED_JUDGE: str = "judge";
glob OWED_VALIDATE: str = "validate";


def relay_repo -> str {
    return os.environ.get("RELAY_REPO") or "";
}


def relay_token -> str {
    return os.environ.get("GITHUB_TOKEN") or "";
}


# The GitHub login of whoever is running this workspace. Only the personal
# views need it ("what is in MY hands"); everything else is impersonal.
def relay_me -> str {
    return os.environ.get("RELAY_ME") or "";
}


def env_hours(name: str, fallback: float) -> float {
    raw = os.environ.get(name) or "";
    if not raw {
        return fallback;
    }
    try {
        return float(raw);
    } except Exception {
        return fallback;
    }
}


def clock_for(owed: str) -> float {
    if owed == OWED_JUDGE {
        return env_hours("RELAY_CLOCK_JUDGE", CLOCK_JUDGE);
    }
    if owed == OWED_VALIDATE {
        return env_hours("RELAY_CLOCK_VALIDATE", CLOCK_VALIDATE);
    }
    return env_hours("RELAY_CLOCK_BUILD", CLOCK_BUILD);
}


# Hours since an ISO-8601 stamp. GitHub sends "2026-08-10T20:19:31Z"; the
# trailing Z is not accepted by fromisoformat before 3.11, so it is swapped
# for the explicit offset.
def hours_since(stamp: str) -> float {
    if not stamp {
        return 0.0;
    }
    try {
        when = datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00"));
    } except Exception {
        return 0.0;
    }
    now = datetime.datetime.now(datetime.timezone.utc);
    return (now - when).total_seconds() / 3600.0;
}


# The value behind a "prefix:value" label, e.g. "kind:bug" -> "bug".
def label_value(labels: list[any], prefix: str) -> str {
    for item in labels {
        name = "";
        if isinstance(item, dict) {
            name = str(item.get("name") or "");
        }
        if name.startswith(prefix) {
            return name[len(prefix):];
        }
    }
    return "";
}


def login_of(item: any) -> str {
    if isinstance(item, dict) {
        return str(item.get("login") or "");
    }
    return "";
}


def first_login(people: any) -> str {
    if not isinstance(people, list) {
        return "";
    }
    for person in people {
        who = login_of(person);
        if who {
            return who;
        }
    }
    return "";
}


# Does this text reference issue #number? Guarded so "#1" does not match
# "#10", which would silently link a PR to the wrong thread.
def mentions_issue(text: str, number: int) -> bool {
    if not text {
        return False;
    }
    try {
        return re.search("#" + str(number) + "(?![0-9])", text) is not None;
    } except Exception {
        return False;
    }
}


# The judge is fixed at birth by the kind, never negotiated later: a bug is
# confirmed by whoever reported it, a feature by whoever owns that surface.
def judge_rule(kind: str, reporter: str) -> str {
    if kind == "feature" {
        return reporter;
    }
    return reporter;
}


# The whole state machine, and the only place a stage is decided.
#
# Order matters: a merged PR outranks an open one, because the newest claim
# on a thread is the one awaiting a verdict.
def derive_thread(issue: dict[str, any], pulls: list[dict[str, any]]) -> RelayThread {
    number = int(issue.get("number") or 0);
    labels = issue.get("labels") or [];
    if not isinstance(labels, list) {
        labels = [];
    }
    kind = label_value(labels, "kind:");
    bet = label_value(labels, "bet:");
    reporter = login_of(issue.get("user"));
    assignee = first_login(issue.get("assignees"));

    merged: dict[str, any] = {};
    opened: dict[str, any] = {};
    has_merged = False;
    has_open = False;
    for pull in pulls {
        blob = str(pull.get("title") or "") + " " + str(pull.get("body") or "");
        if not mentions_issue(blob, number) {
            continue;
        }
        if pull.get("merged_at") {
            merged = pull;
            has_merged = True;
        } elif str(pull.get("state") or "") == "open" {
            opened = pull;
            has_open = True;
        }
    }

    holder = "";
    owed = OWED_BUILD;
    stage = "Unassigned";
    since = str(issue.get("updated_at") or "");
    why = "";
    pr_number = 0;
    pr_state = "";

    if has_merged {
        pr_number = int(merged.get("number") or 0);
        pr_state = "merged";
        owed = OWED_VALIDATE;
        stage = "Awaiting validation";
        holder = judge_rule(kind, reporter);
        since = str(merged.get("merged_at") or since);
        why = "PR #"
            + str(pr_number)
            + " merged while the issue is still open, "
            + "so it returns to "
            + (holder or "nobody")
            + ", who raised it.";
    } elif has_open {
        pr_number = int(opened.get("number") or 0);
        pr_state = "open";
        since = str(opened.get("updated_at") or since);
        reviewer = first_login(opened.get("requested_reviewers"));
        is_draft = opened.get("draft") is True;
        if reviewer {
            owed = OWED_JUDGE;
            stage = "Awaiting review";
            holder = reviewer;
            why = "PR #"
                + str(pr_number)
                + " is open and review was requested "
                + "from "
                + reviewer
                + ".";
        } elif is_draft {
            owed = OWED_BUILD;
            stage = "Implementing";
            holder = login_of(opened.get("user"));
            why = "PR #" + str(pr_number) + " is still a draft.";
        } else {
            owed = OWED_JUDGE;
            stage = "Awaiting review";
            holder = "";
            why = "PR #"
                + str(pr_number)
                + " is ready but NO reviewer has been "
                + "requested, so nobody is holding it.";
        }
    } elif assignee {
        owed = OWED_BUILD;
        stage = "Implementing";
        holder = assignee;
        why = "Assigned to " + assignee + " with no pull request yet.";
    } else {
        owed = OWED_BUILD;
        stage = "Unassigned";
        holder = "";
        why = "Nobody is assigned and there is no pull request.";
    }

    age = hours_since(since);
    clock = clock_for(owed);
    health = "ok";
    if not holder {
        health = "unowned";
    } elif age > clock {
        health = "late";
    }

    return RelayThread(
        number=number,
        title=str(issue.get("title") or ""),
        url=str(issue.get("html_url") or ""),
        bet=bet,
        kind=kind,
        holder=holder,
        owed=owed,
        stage=stage,
        age_hours=age,
        clock_hours=clock,
        health=health,
        pr_number=pr_number,
        pr_state=pr_state,
        why=why
    );
}


def fetch(
    token: str, repo: str, path: str, params: dict[str, any]
) -> list[dict[str, any]] {
    result = gh_request(token, "GET", "/repos/" + repo + path, params);
    if not result["ok"] {
        return [];
    }
    data = result["data"];
    if not isinstance(data, list) {
        return [];
    }
    rows: list[dict[str, any]] = [];
    for item in data {
        if isinstance(item, dict) {
            rows.append(item);
        }
    }
    return rows;
}


walker RelayThreads {
    """Every thread in the configured repo, with its five fields derived.

    Two GitHub reads regardless of repo size. Bare (JWT-required) like every
    walker here. Read-only by construction: this module never calls POST."""
    has results: list[RelayThread] = [],
        configured: bool = False,
        message: str = "",
        reports: list[dict[str, any]] = [];

    can build with Root entry {
        token = relay_token();
        repo = relay_repo();
        if not token or not repo {
            report {
                "configured": False,
                "message": "Set GITHUB_TOKEN and RELAY_REPO in the environment, then restart.",
                "repo": repo,
                "me": "",
                "threads": []
            };
            disengage;
        }

        issues = fetch(
            token, repo, "/issues", {"state": "open", "per_page": RELAY_PAGE}
        );
        pulls = fetch(token, repo, "/pulls", {"state": "all", "per_page": RELAY_PAGE});

        rows: list[RelayThread] = [];
        for issue in issues {
            # The issues endpoint returns pull requests too; a PR is not a
            # thread of its own, it is a claim made ON a thread.
            if issue.get("pull_request") {
                continue;
            }
            rows.append(derive_thread(issue, pulls));
        }
        # Worst first: unowned outranks late, then oldest in hand. This is the
        # only ordering the CEO screen needs, so it is decided once, here.
        rows.sort(key=lambda (t: RelayThread) { 0.0 - t.age_hours; });
        rows.sort(
            key=lambda (t: RelayThread) { 0
                if t.health == "unowned"
                else (1 if t.health == "late" else 2); }
        );
        report {
            "configured": True,
            "message": "",
            "repo": repo,
            "me": relay_me(),
            "threads": rows
        };
    }
}
