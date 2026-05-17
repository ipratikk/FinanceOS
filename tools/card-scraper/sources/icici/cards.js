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

async function fetchCardDetails(
    cardDetailUrl
) {
    try {
        console.log(
            `Fetching: ${cardDetailUrl}`
        );

        const response =
            await fetch(
                cardDetailUrl,
                {
                    headers: {
                        "User-Agent":
                            "Mozilla/5.0"
                    }
                }
            );

        if (
            !response.ok
        ) {
            return null;
        }

        const html =
            await response.text();

        const $ =
            cheerio.load(
                html
            );

        // Extract product name (clean title)
        const title =
            $("title").text();

        let productName =
            title
                .split(":")[0]
                .split("|")[0]
                .split("–")[0]
                .trim();

        // Clean product name of extra chars
        productName =
            productName
                .replace(
                    /\s+/g,
                    " "
                );

        // Extract description
        let description =
            $('meta[property="og:description"]')
                .attr("content") ||
            "";

        if (
            description
        ) {
            description =
                description
                    .slice(0, 400);
        }

        // Extract rewards from description as fallback
        const rewards =
            [];

        // Try to get reward points info
        $(
            ".icon__benefit img[src*='reward'], " +
            ".icon__benefit img[src*='points']"
        )
            .closest(".icon__benefit")
            .find("p").each(
                (_, elem) => {
                    const text =
                        $(elem)
                            .text()
                            .trim()
                            .replace(
                                /\n/g,
                                " "
                            )
                            .replace(
                                /\s+/g,
                                " "
                            );

                    if (
                        text &&
                        text.length > 15
                    ) {
                        rewards.push(
                            text
                        );
                    }
                }
            );

        // Extract benefits category names
        const benefits =
            [];

        $(
            ".benefits__lt .dis__badge p, " +
            ".product-maximum-benefits .dis__badge p"
        ).each(
            (_, elem) => {
                const text =
                    $(elem)
                        .text()
                        .trim();

                if (
                    text &&
                    benefits.length < 5
                ) {
                    benefits.push(
                        text
                    );
                }
            }
        );

        // Extract apply link
        const applyLink =
            $('a[href*="buy.icici.bank"]')
                .first()
                .attr("href") || null;

        return {
            productName,

            description,

            rewards:
                rewards.slice(0, 5),

            benefits:
                benefits.slice(0, 5),

            applyLink,

            detailsLink:
                cardDetailUrl
        };
    } catch (error) {
        return null;
    }
}

const CARD_PAGE_KEYWORDS = [
    "credit-card",
    "rupay",
    "signature",
    "platinum",
    "coral",
    "sapphiro",
    "rubyx",
    "emeralde",
    "hpcl",
    "adani",
    "manchester",
    "mmt",
    "makemytrip",
    "emirates",
    "expressions",
    "parakram",
    "times-black",
    "csk"
];

function isCardProductPage(
    url
) {
    const lower =
        url.toLowerCase();

    const hasCardKeyword =
        CARD_PAGE_KEYWORDS.some(
            keyword =>
                lower.includes(
                    keyword
                )
        );

    const isNotServicePage =
        !lower.includes(
            "faq"
        ) &&
        !lower.includes(
            "cancel"
        ) &&
        !lower.includes(
            "pin"
        ) &&
        !lower.includes(
            "limit"
        ) &&
        !lower.includes(
            "emi"
        ) &&
        !lower.includes(
            "terms"
        ) &&
        !lower.includes(
            "benefits-and-features"
        ) &&
        !lower.includes(
            "experience"
        ) &&
        !lower.includes(
            "generate"
        ) &&
        !lower.includes(
            "calculator"
        );

    return hasCardKeyword &&
        isNotServicePage;
}

function fuzzyMatch(
    str1,
    str2
) {
    const a =
        str1
            .toLowerCase()
            .replace(/\W/g, "");
    const b =
        str2
            .toLowerCase()
            .replace(/\W/g, "");

    return (
        a.includes(b) ||
        b.includes(a) ||
        a === b
    );
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

    // Extract product card URLs only
    const cardUrls =
        new Set();

    $(
        'a[href*="/personal-banking/cards/credit-card/"]'
    ).each(
        (_, elem) => {
            const href =
                $(elem).attr(
                    "href"
                );

            if (
                href &&
                isCardProductPage(
                    href
                )
            ) {
                cardUrls.add(
                    href
                );
            }
        }
    );

    console.log(
        `Found ${cardUrls.size} product card pages`
    );

    // Extract all card images from listing with context
    const allImages =
        [];

    $("img").each(
        (_, imageElement) => {
            const image =
                $(imageElement).attr(
                    "src"
                );

            if (
                !image
            ) {
                return;
            }

            const rawName =
                extractRawCardName(
                    image
                );

            const cleanName =
                cleanICICIName(
                    rawName
                );

            if (
                !cleanName
            ) {
                return;
            }

            const absoluteImage =
                image.startsWith(
                    "http"
                )
                    ? image
                    : `https://www.icici.bank.in${image}`;

            allImages.push({
                cleanName,
                rawName,
                absoluteImage
            });
        }
    );

    console.log(
        `Extracted ${allImages.length} card images`
    );

    // Fetch details for each card
    const cards =
        [];

    for (const url of cardUrls) {
        const fullUrl =
            url.startsWith(
                "http"
            )
                ? url
                : `https://www.icici.bank.in${url}`;

        const details =
            await fetchCardDetails(
                fullUrl
            );

        if (
            !details ||
            !details.applyLink
        ) {
            continue;
        }

        const cardName =
            details.productName;

        // Match image by fuzzy name matching
        let matchedImage =
            null;

        for (const imgData of allImages) {
            if (
                fuzzyMatch(
                    cardName,
                    imgData.cleanName
                ) ||
                fuzzyMatch(
                    cardName,
                    imgData.rawName
                )
            ) {
                matchedImage =
                    imgData.absoluteImage;
                break;
            }
        }

        cards.push({
            name:
                cardName,

            image:
                matchedImage,

            description:
                details.description,

            rewards:
                details.rewards,

            benefits:
                details.benefits,

            applyLink:
                details.applyLink,

            detailsLink:
                details.detailsLink
        });
    }

    // Deduplicate by name
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
