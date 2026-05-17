import * as cheerio
from "cheerio";

const PAGE_URL =
    "https://www.icici.bank.in/personal-banking/cards/credit-card";

const INVALID_IMAGE_PATTERNS = [
    "header",
    "logo",
    "banner",
    "icon",
    "newsletter",
    "service",
    "netbanking",
    "imobile",
    "Password.svg",
    "person.png"
];

const INVALID_CARD_NAMES = [
    "cclandingpage",
    "dual cards"
];

const ICICI_NAME_MAPPINGS = {
    sapphiro:
        "Sapphiro Credit Card",

    rubyx:
        "Rubyx Credit Card",

    emeralde:
        "Emeralde Credit Card",

    "emerald metal":
        "Emeralde Metal Credit Card",

    coral:
        "Coral Credit Card",

    "hpcl supersaver":
        "HPCL Super Saver Credit Card",

    "times black":
        "Times Black Credit Card",

    "adani one signature":
        "Adani One Signature Credit Card",

    "mmt signature":
        "MakeMyTrip Signature Credit Card",

    "mmt platinum":
        "MakeMyTrip Platinum Credit Card",

    parakram:
        "Parakram Credit Card",

    "parakram select":
        "Parakram Select Credit Card",

    "emirates sapphiro":
        "Emirates Sapphiro Credit Card",

    "emirates rubyx":
        "Emirates Rubyx Credit Card",

    expressions:
        "Expressions Credit Card",

    "manchester signature":
        "Manchester United Signature Credit Card",

    "manchester platinum":
        "Manchester United Platinum Credit Card",

    csk:
        "CSK Credit Card"
};

function isValidCardImage(
    image
) {
    if (!image) {
        return false;
    }

    const normalized =
        image.toLowerCase();

    if (
        !normalized.includes(
            "card"
        ) &&
        !normalized.includes(
            "cards"
        )
    ) {
        return false;
    }

    const invalid =
        INVALID_IMAGE_PATTERNS.some(
            pattern =>
                normalized.includes(
                    pattern
                )
        );

    return !invalid;
}

function extractRawCardName(
    image
) {
    return image
        .split("/")
        .pop()
        ?.replace(
            /\.webp$/g,
            ""
        )
        ?.replace(
            /\.png$/g,
            ""
        )
        ?.replace(
            /\.jpg$/g,
            ""
        )
        ?.replaceAll(
            "-",
            " "
        )
        ?.replaceAll(
            "_",
            " "
        )
        ?.trim();
}

function cleanICICIName(
    rawName
) {
    if (!rawName) {
        return null;
    }

    let normalized =
        rawName
            .toLowerCase()
            .replace(
                /desktop/g,
                ""
            )
            .replace(
                /desk/g,
                ""
            )
            .replace(
                /card d/g,
                ""
            )
            .replace(
                /crad d/g,
                ""
            )
            .replace(
                /-d$/g,
                ""
            )
            .replace(
                /02/g,
                ""
            )
            .replace(
                /\s+/g,
                " "
            )
            .trim();

    if (
        INVALID_CARD_NAMES.includes(
            normalized
        )
    ) {
        return null;
    }

    for (const [
        key,
        value
    ] of Object.entries(
        ICICI_NAME_MAPPINGS
    )) {
        if (
            normalized.includes(
                key
            )
        ) {
            return value;
        }
    }

    return normalized
        .split(" ")
        .map(
            word =>
                word.charAt(0)
                    .toUpperCase() +
                word.slice(1)
        )
        .join(" ");
}

export async function fetchICICICards() {
    console.log(
        "Fetching ICICI listing page..."
    );

    const response =
        await fetch(
            PAGE_URL,
            {
                headers: {
                    "User-Agent":
                        "Mozilla/5.0"
                }
            }
        );

    const html =
        await response.text();

    const $ =
        cheerio.load(
            html
        );

    const cards =
        [];

    $("img").each(
        (_, imageElement) => {
            const image =
                $(imageElement).attr(
                    "src"
                );

            if (
                !isValidCardImage(
                    image
                )
            ) {
                return;
            }

            const rawName =
                extractRawCardName(
                    image
                );

            const name =
                cleanICICIName(
                    rawName
                );

            if (
                !name
            ) {
                return;
            }

            const absoluteImage =
                image.startsWith(
                    "http"
                )
                    ? image
                    : `https://www.icici.bank.in${image}`;

            const container =
                $(imageElement)
                    .closest(
                        "section, div, article, li"
                    );

            const description =
                container
                    .text()
                    .replace(
                        /\s+/g,
                        " "
                    )
                    .trim()
                    .slice(
                        0,
                        400
                    );

            cards.push({
                name,

                image:
                    absoluteImage,

                description
            });
        }
    );

    const unique =
        Array.from(
            new Map(
                cards.map(
                    card => [
                        card.name,
                        card
                    ]
                )
            ).values()
        );

    return unique.sort(
        (
            a,
            b
        ) =>
            a.name.localeCompare(
                b.name
            )
    );
}
