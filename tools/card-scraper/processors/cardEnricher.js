import Anthropic from "@anthropic-ai/sdk";
import * as fs from "fs";
import { execSync } from "child_process";

const client = new Anthropic();

const VALID_BENEFIT_CATEGORIES = [
    "Travel",
    "Dining",
    "Shopping",
    "Lifestyle",
    "Fuel",
    "Entertainment",
    "Rewards",
    "Insurance",
    "Lounge Access"
];

async function enrichCards(
    rawCards,
    bank,
    cardImages
) {
    const imageList = Array.from(
        cardImages.entries()
    ).map(([name, url]) => ({
        cardName: name,
        imageUrl: url
    }));

    const prompt = `You are a credit card data enrichment specialist. Process raw card data for ${bank} bank.

RAW CARDS DATA:
${JSON.stringify(rawCards.slice(0, 50), null, 2)}
${rawCards.length > 50 ? `\n... (${rawCards.length - 50} more cards) ...` : ""}

AVAILABLE IMAGES (to match with cards):
${JSON.stringify(imageList.slice(0, 30), null, 2)}
${imageList.length > 30 ? `\n... (${imageList.length - 30} more images) ...` : ""}

TASK - Process each card:

1. **Normalize name**: Remove bank prefix (ICICI Bank, HDFC Bank), remove "Credit Card" suffix. Keep brand + key variant (Signature, Platinum, etc.)
   - "HDFC Bank Millennia Credit Card" → "Millennia Credit Card"
   - "ICICI Bank Sapphiro Credit Card" → "Sapphiro Credit Card"

2. **Match image**: Find best image URL match using semantic similarity
   - Fuzzy match card name to image card name
   - Return the full HTTPS image URL from imageList
   - If no match found, set to null (card will be dropped in validation)

3. **Extract rewards array**: Parse description/benefits text for concrete rewards
   - Look for: cashback %, points earned, vouchers, discounts, fee waivers
   - Examples: "5% cashback on Amazon", "₹1000 voucher on ₹1L spend", "No annual fee"
   - Return array of 1-5 reward strings, minimum 15 characters each
   - If can't find specific rewards, extract from benefit descriptions

4. **Extract benefits array**: Categorize benefits into standard categories
   - Valid categories: ${VALID_BENEFIT_CATEGORIES.join(", ")}
   - Parse text keywords (lounge, airport, travel, dining, shopping, etc.)
   - Return 1-4 categories from the valid list
   - If unknown category, use "Lifestyle"

5. **Validate fields**:
   - name: non-empty string (required)
   - description: string, can be empty
   - image: HTTPS URL or null (card dropped if null)
   - applyLink: HTTPS URL (required, card dropped if missing)
   - detailsLink: HTTPS URL (required)
   - rewards: array of strings, ≥1 item (required)
   - benefits: array of categories, ≥1 item (required)

6. **Deduplicate**: Keep only one card per name (prefer cards with images)

OUTPUT:
Return ONLY valid JSON array wrapped in \`\`\`json ... \`\`\`, no extra text.

Example output structure:
\`\`\`json
[
  {
    "name": "Millennia Credit Card",
    "description": "Earn 5% cashback on online shopping.",
    "image": "https://www.hdfcbank.com/content/dam/.../millennia.png",
    "applyLink": "https://applyonline.hdfc.bank.in/...",
    "detailsLink": "https://www.hdfc.bank.in/credit-cards/millennia",
    "rewards": ["5% cashback on Amazon, Flipkart, Myntra", "₹1000 gift voucher on ₹1L quarterly spend"],
    "benefits": ["Shopping", "Dining"]
  }
]
\`\`\`

Process ALL ${rawCards.length} cards. Ensure image URLs are complete HTTPS URLs from the imageList.`;

    console.log(
        `Calling Claude (${rawCards.length} cards)...`
    );

    const response =
        await client.messages.create({
            model: "claude-opus-4-7",
            max_tokens: 8000,
            messages: [
                {
                    role: "user",
                    content: prompt
                }
            ]
        });

    const content =
        response.content[0];

    if (
        content.type !==
        "text"
    ) {
        throw new Error(
            "Unexpected response type"
        );
    }

    let jsonText =
        content.text;

    // Extract JSON from markdown code blocks
    const jsonMatch =
        jsonText.match(
            /```json\n?([\s\S]*?)\n?```/
        );

    if (jsonMatch) {
        jsonText = jsonMatch[1];
    }

    return JSON.parse(
        jsonText
    );
}

function validateCard(card) {
    const errors = [];

    if (
        !card.name ||
        typeof card.name !==
        "string"
    ) {
        errors.push(
            "Missing name"
        );
    }

    if (
        !card.image ||
        !card.image.startsWith(
            "http"
        )
    ) {
        errors.push(
            "Missing/invalid image URL"
        );
    }

    if (
        !card.applyLink ||
        !card.applyLink.startsWith(
            "http"
        )
    ) {
        errors.push(
            "Missing/invalid applyLink"
        );
    }

    if (
        !card.detailsLink ||
        !card.detailsLink.startsWith(
            "http"
        )
    ) {
        errors.push(
            "Missing/invalid detailsLink"
        );
    }

    if (
        !Array.isArray(
            card.rewards
        ) ||
        card.rewards.length ===
        0
    ) {
        errors.push(
            "Missing rewards"
        );
    }

    if (
        !Array.isArray(
            card.benefits
        ) ||
        card.benefits.length ===
        0
    ) {
        errors.push(
            "Missing benefits"
        );
    }

    return errors;
}

async function processBank(
    bank,
    rawFile,
    outputFile
) {
    console.log(
        `\n=== Processing ${bank} ===`
    );

    if (
        !fs.existsSync(rawFile)
    ) {
        console.error(
            `Raw file not found: ${rawFile}`
        );
        return [];
    }

    const rawData = JSON.parse(
        fs.readFileSync(
            rawFile,
            "utf-8"
        )
    );

    console.log(
        `Loaded ${rawData.length} raw cards`
    );

    // Extract all available images
    const cardImages =
        new Map();

    for (const card of rawData) {
        const name =
            card.cardTitle ||
            card.name ||
            "";

        if (
            card.image &&
            name
        ) {
            cardImages.set(
                name,
                card.image
            );
        }
    }

    console.log(
        `Found ${cardImages.size} images`
    );

    // Enrich cards
    const enriched =
        await enrichCards(
            rawData,
            bank,
            cardImages
        );

    // Validate
    const valid = [];
    const invalid = [];

    for (const card of enriched) {
        const errors =
            validateCard(card);

        if (errors.length === 0) {
            valid.push(card);
        } else {
            invalid.push({
                name: card.name,
                errors
            });
        }
    }

    console.log(
        `Valid: ${valid.length}, Invalid: ${invalid.length}`
    );

    if (invalid.length > 0) {
        console.log(
            "Dropped cards:"
        );
        for (const item of invalid) {
            console.log(
                `  - ${item.name}: ${item.errors.join(", ")}`
            );
        }
    }

    // Save output
    fs.writeFileSync(
        outputFile,
        JSON.stringify(
            valid,
            null,
            2
        )
    );

    console.log(
        `Saved ${valid.length} cards to ${outputFile}`
    );

    return valid;
}

async function main() {
    try {
        console.log(
            "Starting scraper pipeline..."
        );

        // Run scrapers
        console.log(
            "\n1. Running HDFC scraper..."
        );
        execSync("npm run hdfc", {
            stdio: "inherit"
        });

        console.log(
            "\n2. Running ICICI scraper..."
        );
        execSync("npm run icici", {
            stdio: "inherit"
        });

        // Enrich data
        const outputDir =
            "./output/normalized";

        if (
            !fs.existsSync(
                outputDir
            )
        ) {
            fs.mkdirSync(
                outputDir,
                { recursive: true }
            );
        }

        console.log(
            "\n3. Enriching data with Claude..."
        );

        const hdfcCards =
            await processBank(
                "HDFC",
                "./output/raw/hdfc_raw.json",
                `${outputDir}/hdfc_cards.json`
            );

        const iciciCards =
            await processBank(
                "ICICI",
                "./output/raw/icici_raw.json",
                `${outputDir}/icici_cards.json`
            );

        // Summary
        const total =
            hdfcCards.length +
            iciciCards.length;

        console.log(
            `\n=== SUMMARY ===`
        );
        console.log(
            `HDFC: ${hdfcCards.length} cards`
        );
        console.log(
            `ICICI: ${iciciCards.length} cards`
        );
        console.log(
            `Total: ${total} cards`
        );

        console.log(
            "\n✓ Pipeline complete!"
        );
    } catch (error) {
        console.error(
            "\nError:",
            error.message
        );
        process.exit(1);
    }
}

main();
