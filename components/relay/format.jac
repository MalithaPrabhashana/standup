"""Shared formatting for the Relay screens.

Client-side only, so no Python may enter this module. Every screen renders
the same vocabulary from here: an age reads the same on the CEO page as it
does on an engineer's, because a shared word is the whole point of giving
work one shape.
"""

glob OWED_LABEL: dict[str, str] = {
         "build": "BUILD",
         "judge": "JUDGE",
         "validate": "VALIDATE"
     };

# Health drives colour everywhere. Never colour-alone: each pill also carries
# a word, so the state survives a colourblind reader and a greyscale print.
glob HEALTH_LABEL: dict[str, str] = {
         "unowned": "nobody holding",
         "late": "past clock",
         "ok": "within clock"
     };


# Hours as something a human reads at a glance. Anything under an hour is
# minutes, because "0.3h" is a number you have to decode.
def humanAge(hours: float) -> str {
    if hours < 0.0166 {
        return "just now";
    }
    if hours < 1.0 {
        return str(int(hours * 60.0)) + "m";
    }
    if hours < 48.0 {
        return str(int(hours)) + "h";
    }
    return str(int(hours / 24.0)) + "d";
}


# Never returns "0m": a clock of zero reads as a bug, not as a policy.
def humanClock(hours: float) -> str {
    if hours < 1.0 {
        mins = int(hours * 60.0);
        return str(mins if mins > 0 else 1) + "m";
    }
    if hours < 48.0 {
        return str(int(hours)) + "h";
    }
    return str(int(hours / 24.0)) + "d";
}


# The one sentence a row is really saying. This is the product: not a column
# name, but who it waits on and for how long.
def waitingSentence(holder: str, owed: str, hours: float) -> str {
    who = holder if holder else "nobody";
    verb = "build it";
    if owed == "judge" {
        verb = "review it";
    }
    if owed == "validate" {
        verb = "confirm it is fixed";
    }
    return "Waiting on " + who + " to " + verb + " for " + humanAge(hours) + ".";
}


def healthTone(health: str) -> str {
    if health == "unowned" {
        return "text-[var(--relay-crit)] bg-[var(--relay-crit-soft)]";
    }
    if health == "late" {
        return "text-[var(--relay-warn)] bg-[var(--relay-warn-soft)]";
    }
    return "text-[var(--relay-good)] bg-[var(--relay-good-soft)]";
}


def healthDot(health: str) -> str {
    if health == "unowned" {
        return "var(--relay-crit)";
    }
    if health == "late" {
        return "var(--relay-warn)";
    }
    return "var(--relay-good)";
}


def owedTone(owed: str) -> str {
    if owed == "judge" {
        return "text-[var(--relay-warn)] bg-[var(--relay-warn-soft)]";
    }
    if owed == "validate" {
        return "text-[var(--relay-good)] bg-[var(--relay-good-soft)]";
    }
    return "text-[var(--relay-accent)] bg-[var(--relay-accent-soft)]";
}


def betLabel(bet: str) -> str {
    if not bet {
        return "no bet";
    }
    return bet;
}


# Short labels are acronyms ("ux"), longer ones are words ("reliability"), so
# a blanket CSS capitalize would render "Ux". Decide it here instead.
def betDisplay(bet: str) -> str {
    label = betLabel(bet);
    if len(label) <= 3 {
        return label.upper();
    }
    return label[0].upper() + label[1:];
}


def initials(name: str) -> str {
    if not name {
        return "?";
    }
    return name[:2].upper();
}
