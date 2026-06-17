require('dotenv').config();
const neo4j = require('neo4j-driver');

const driver = neo4j.driver(
    'bolt://localhost:7687',
    neo4j.auth.basic(process.env.NEO4J_USER || 'neo4j', process.env.NEO4J_PASSWORD || 'truthnet123')
);

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

async function callAIBatch(comments) {
    const res = await fetch(`${AI_SERVICE_URL}/analyze/batch/comments`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ comments }),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
}

async function runMigration() {
    const session = driver.session();
    console.log("[Migration] Looking for unanalyzed comments in Neo4j...");

    try {
        // Find all comments that haven't been analyzed yet
        const result = await session.run(`
            MATCH (c:Comment)
            WHERE c.ai_analyzed IS NULL OR c.ai_analyzed = false
            RETURN c.id as id, c.content as content
        `);

        const comments = result.records.map(r => ({
            id: r.get('id'),
            text: r.get('content')
        }));

        if (comments.length === 0) {
            console.log("[Migration] All comments are already analyzed.");
            return;
        }

        console.log(`[Migration] Found ${comments.length} comments. Sending to AI for batch analysis...`);
        console.log("   (This might take a moment depending on your CPU...)");

        // Send them in one batch to the AI service
        const aiResponse = await callAIBatch(comments);

        if (!aiResponse.success) {
            throw new Error("AI service returned success: false");
        }

        console.log("[Migration] AI analysis complete. Saving results to database...");

        // Update Neo4j
        let updatedCount = 0;
        for (const item of aiResponse.per_comment) {
            await session.run(`
                MATCH (c:Comment {id: $id})
                SET c.ai_sentiment        = $sentiment,
                    c.ai_sentiment_score  = $sentimentScore,
                    c.ai_toxic_score      = $toxicScore,
                    c.ai_is_toxic         = $isToxic,
                    c.ai_degree           = $degree,
                    c.ai_analyzed         = true
            `, {
                id: item.id,
                sentiment:      item.sentiment.label,
                sentimentScore: item.sentiment.confidence,
                toxicScore:     item.toxicity.toxic_score,
                isToxic:        item.toxicity.is_toxic,
                degree:         item.toxicity.degree,
            });
            updatedCount++;
            process.stdout.write(`\r   Progress: ${updatedCount} / ${comments.length}`);
        }

        console.log("\n[Migration] Complete. The dashboard will now reflect all comments.");

    } catch (e) {
        console.error("\n[Error] Error during migration:", e.message);
    } finally {
        await session.close();
        await driver.close();
    }
}

runMigration();