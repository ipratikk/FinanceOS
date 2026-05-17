#!/usr/bin/env node

import * as fs from "fs";

const ISSUER_CONFIG = {
    hdfc: {
        id: "hdfc",
        name: "HDFC Bank",
        country: "IN",
        website: "https://www.hdfcbank.com",
        brandColor: "#004B8D",
        logoUrl:
            "https://upload.wikimedia.org/wikipedia/en/0/0a/HDFC_bank_logo.svg"
    },

    icici: {
        id: "icici",
        name: "ICICI Bank",
        country: "IN",
        website: "https://www.icici.bank.in",
        brandColor: "#003D7A",
        logoUrl:
            "https://upload.wikimedia.org/wikipedia/en/c/c0/ICICI_Bank_Logo.svg"
    }
};

function generateCardId(
    name,
    bank
) {
    return (
        `${bank}-` +
        name
            .toLowerCase()
            .replace(
                /\s+/g,
                "-"
            )
            .replace(
                /[^a-z0-9-]/g,
                ""
            )
            .slice(0, 40)
    );
}

function transformCard(
    rawCard,
    bank
) {
    const id = generateCardId(
        rawCard.name,
        bank
    );

    const theme =
        bank === "hdfc"
            ? {
                  primaryColor:
                      "#004B8D",
                  secondaryColor:
                      "#D4AF37",
                  textColor:
                      "#FFFFFF",
                  accentColor:
                      "#D4AF37"
              }
            : {
                  primaryColor:
                      "#003D7A",
                  secondaryColor:
                      "#FFD700",
                  textColor:
                      "#FFFFFF",
                  accentColor:
                      "#FFD700"
              };

    return {
        id,

        name: rawCard.name,

        type: "Credit Card",

        network:
            "Visa", // Default to Visa

        variant: "credit",

        active: true,

        premiumTier: false,

        aliases: [rawCard.name],

        binRanges: [],

        image: {
            front: rawCard.image,

            thumbnail: rawCard.image,

            localAssetName: id,

            aspectRatio: "16:10"
        },

        theme,

        details: {
            annualFee:
                "Check issuer website",

            joiningBenefit:
                "Check issuer website",

            interestRate:
                "Check issuer website",

            gracePeriod: "45 days",

            description:
                rawCard.description ||
                rawCard.name,

            rewards:
                rawCard.rewards,

            benefits:
                rawCard.benefits,

            applyUrl:
                rawCard.applyLink,

            detailsUrl:
                rawCard.detailsLink,

            updatedAt: new Date()
                .toISOString()
        },

        eligibility: {
            minimumAge: 21,

            minimumIncome:
                "Check issuer website",

            creditScore:
                "Good (650+)"
        }
    };
}

function main() {
    const hdfcRaw = JSON.parse(
        fs.readFileSync(
            "./output/normalized/hdfc_cards.json",
            "utf-8"
        )
    );

    const iciciRaw = JSON.parse(
        fs.readFileSync(
            "./output/normalized/icici_cards.json",
            "utf-8"
        )
    );

    // Transform to catalog schema
    const hdfcCards = hdfcRaw.map(
        card =>
            transformCard(
                card,
                "hdfc"
            )
    );

    const iciciCards = iciciRaw.map(
        card =>
            transformCard(
                card,
                "icici"
            )
    );

    // Build catalog
    const catalog = {
        version: 3,

        generatedAt: new Date()
            .toISOString(),

        issuers: [
            {
                ...ISSUER_CONFIG.hdfc,

                cards: hdfcCards
            },

            {
                ...ISSUER_CONFIG.icici,

                cards: iciciCards
            }
        ]
    };

    // Save
    const outDir =
        "../../Packages/FinanceCore/Sources/FinanceCore/Resources";

    fs.writeFileSync(
        `${outDir}/cards_catalog.json`,
        JSON.stringify(
            catalog,
            null,
            2
        )
    );

    console.log(
        `✅ Catalog generated: ${hdfcCards.length} HDFC + ${iciciCards.length} ICICI cards`
    );
    console.log(
        `Saved to: ${outDir}/cards_catalog.json`
    );
}

try {
    main();
} catch (error) {
    console.error(
        error
    );
    process.exit(1);
}
