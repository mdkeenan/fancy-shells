#!/usr/bin/env python
"""fspw - random password/passphrase generator."""
import argparse
import secrets
import string
import sys

WORDLIST = [
    "amber", "anchor", "azure", "basil", "birch", "canyon", "cedar", "comet",
    "coral", "cosmic", "crimson", "crystal", "delta", "ember", "falcon", "fjord",
    "forest", "galaxy", "garnet", "glacier", "granite", "harbor", "hazel", "indigo",
    "ivory", "jasper", "juniper", "lagoon", "lantern", "lunar", "maple", "marble",
    "meadow", "mesa", "meteor", "mint", "nebula", "nomad", "oasis", "obsidian",
    "onyx", "opal", "orbit", "orchid", "otter", "pebble", "pine", "prairie",
    "quartz", "raven", "reef", "ridge", "river", "rustic", "saffron", "sapphire",
    "shadow", "silver", "solar", "sparrow", "spruce", "storm", "summit", "sunset",
    "tempest", "thunder", "tidal", "timber", "topaz", "tundra", "valley", "velvet",
    "violet", "willow", "zenith",
]


def generate_password(length, use_symbols, use_digits, use_upper):
    alphabet = list(string.ascii_lowercase)
    if use_upper:
        alphabet += list(string.ascii_uppercase)
    if use_digits:
        alphabet += list(string.digits)
    if use_symbols:
        alphabet += list("!@#$%^&*()-_=+[]{}")
    return "".join(secrets.choice(alphabet) for _ in range(length))


def generate_passphrase(num_words, separator):
    words = [secrets.choice(WORDLIST) for _ in range(num_words)]
    return separator.join(words)


def main():
    parser = argparse.ArgumentParser(prog="fspw", description="Generate random passwords or passphrases.")
    parser.add_argument("-l", "--length", type=int, default=16, help="password length (default: 16)")
    parser.add_argument("-n", "--count", type=int, default=1, help="how many to generate")
    parser.add_argument("--no-symbols", action="store_true", help="exclude symbols")
    parser.add_argument("--no-digits", action="store_true", help="exclude digits")
    parser.add_argument("--no-upper", action="store_true", help="exclude uppercase letters")
    parser.add_argument(
        "-p", "--passphrase", action="store_true", help="generate a word-based passphrase instead"
    )
    parser.add_argument("-w", "--words", type=int, default=4, help="number of words in passphrase (default: 4)")
    parser.add_argument("-s", "--separator", default="-", help="separator for passphrase words (default: '-')")
    args = parser.parse_args()

    if args.length < 4 and not args.passphrase:
        print("fspw: length must be at least 4", file=sys.stderr)
        sys.exit(1)

    for _ in range(args.count):
        if args.passphrase:
            print(generate_passphrase(args.words, args.separator))
        else:
            print(generate_password(
                args.length,
                use_symbols=not args.no_symbols,
                use_digits=not args.no_digits,
                use_upper=not args.no_upper,
            ))


if __name__ == "__main__":
    main()
