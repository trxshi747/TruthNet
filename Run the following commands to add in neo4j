// ─────────────────────────────────────────────────────────────────────────────
// TruthNet — Comment seed for AI model testing
// 30 comments: 10 positive · 10 neutral · 10 negative/toxic
// Distributed across 3 real users + 3 dummy posts
// Paste entirely in Neo4j Browser and hit ▶ Run
// ─────────────────────────────────────────────────────────────────────────────

// ── 0. Bind the 3 real users ──────────────────────────────────────────────────
MATCH (u1:User {id: "c0195fd0-8857-4726-a63a-4ec209893b3f"})   // user20
MATCH (u2:User {id: "cb041855-d57c-465c-8aa3-bb19015eab4e"})   // test
MATCH (u3:User {id: "c3abfb6d-59b8-4962-be61-0d5df4ac39d1"})   // Mo45d

// ── 1. Create 3 dummy posts to attach comments to ────────────────────────────
MERGE (p1:Post {id: "seed-post-001"})
  ON CREATE SET
    p1.content    = "What do you think about the new platform features?",
    p1.visibility = "public",
    p1.isDeleted  = false,
    p1.createdAt  = timestamp() - 86400000   // 1 day ago
MERGE (u1)-[:OWNS_POST]->(p1)

MERGE (p2:Post {id: "seed-post-002"})
  ON CREATE SET
    p2.content    = "Share your experience using TruthNet today.",
    p2.visibility = "public",
    p2.isDeleted  = false,
    p2.createdAt  = timestamp() - 172800000  // 2 days ago
MERGE (u2)-[:OWNS_POST]->(p2)

MERGE (p3:Post {id: "seed-post-003"})
  ON CREATE SET
    p3.content    = "Community discussion: rules and moderation.",
    p3.visibility = "public",
    p3.isDeleted  = false,
    p3.createdAt  = timestamp() - 259200000  // 3 days ago
MERGE (u3)-[:OWNS_POST]->(p3)

// ─────────────────────────────────────────────────────────────────────────────
// ── 2. POSITIVE comments (expected: positive sentiment, low toxicity) ─────────
// ─────────────────────────────────────────────────────────────────────────────

// C01 — user20 on post 1
CREATE (c01:Comment {
  id: "seed-c01", content: "I absolutely love this platform! The interface is clean and everything works perfectly. Keep up the amazing work team!",
  createdAt: timestamp() - 82000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c01)
CREATE (c01)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c01)

// C02 — test on post 1
CREATE (c02:Comment {
  id: "seed-c02", content: "This is genuinely one of the best social platforms I have used. The moderation is fair and the community is kind.",
  createdAt: timestamp() - 80000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c02)
CREATE (c02)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c02)

// C03 — Mo45d on post 2
CREATE (c03:Comment {
  id: "seed-c03", content: "Wonderful experience today! Met some great people and had really meaningful conversations. Feeling very positive about this community.",
  createdAt: timestamp() - 78000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c03)
CREATE (c03)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c03)

// C04 — user20 on post 2
CREATE (c04:Comment {
  id: "seed-c04", content: "Thank you for building such a transparent and honest platform. It is refreshing to see social media done right.",
  createdAt: timestamp() - 76000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c04)
CREATE (c04)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c04)

// C05 — test on post 3
CREATE (c05:Comment {
  id: "seed-c05", content: "The moderation team is doing a fantastic job. I feel safe here and the rules are very reasonable. Big thanks!",
  createdAt: timestamp() - 74000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c05)
CREATE (c05)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c05)

// C06 — Mo45d on post 3
CREATE (c06:Comment {
  id: "seed-c06", content: "Just wanted to say this place makes me happy every day. The people here are so supportive and uplifting!",
  createdAt: timestamp() - 72000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c06)
CREATE (c06)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c06)

// C07 — user20 on post 3
CREATE (c07:Comment {
  id: "seed-c07", content: "Great discussion everyone! I learned so much from this thread. This is exactly the kind of constructive dialogue we need.",
  createdAt: timestamp() - 70000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c07)
CREATE (c07)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c07)

// C08 — test on post 2
CREATE (c08:Comment {
  id: "seed-c08", content: "I recommended this platform to all my friends. The experience has been nothing short of excellent. Very impressed!",
  createdAt: timestamp() - 68000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c08)
CREATE (c08)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c08)

// C09 — Mo45d on post 1
CREATE (c09:Comment {
  id: "seed-c09", content: "Loving the new features! The search works great and the feed is perfectly curated. You guys really nailed it.",
  createdAt: timestamp() - 66000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c09)
CREATE (c09)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c09)

// C10 — user20 on post 1
CREATE (c10:Comment {
  id: "seed-c10", content: "Such a breath of fresh air compared to other platforms. Honest, clean, and well designed. Proud to be part of this community.",
  createdAt: timestamp() - 64000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c10)
CREATE (c10)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c10)

// ─────────────────────────────────────────────────────────────────────────────
// ── 3. NEUTRAL comments (expected: neutral sentiment, low toxicity) ───────────
// ─────────────────────────────────────────────────────────────────────────────

// C11 — test on post 1
CREATE (c11:Comment {
  id: "seed-c11", content: "I signed up yesterday. Still exploring the features. Will share my thoughts once I have used it more.",
  createdAt: timestamp() - 62000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c11)
CREATE (c11)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c11)

// C12 — Mo45d on post 2
CREATE (c12:Comment {
  id: "seed-c12", content: "The platform seems fine. Nothing particularly exciting but nothing bad either. It does what it says.",
  createdAt: timestamp() - 60000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c12)
CREATE (c12)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c12)

// C13 — user20 on post 2
CREATE (c13:Comment {
  id: "seed-c13", content: "Can someone explain how the follower system works? I am not sure if it is mutual or one way.",
  createdAt: timestamp() - 58000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c13)
CREATE (c13)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c13)

// C14 — test on post 3
CREATE (c14:Comment {
  id: "seed-c14", content: "The rules seem standard. Similar to most platforms. I will read through them when I have time.",
  createdAt: timestamp() - 56000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c14)
CREATE (c14)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c14)

// C15 — Mo45d on post 3
CREATE (c15:Comment {
  id: "seed-c15", content: "Moderation policy updated last week apparently. Have not read the full changelog yet.",
  createdAt: timestamp() - 54000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c15)
CREATE (c15)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c15)

// C16 — user20 on post 3
CREATE (c16:Comment {
  id: "seed-c16", content: "I have a question about data privacy. Where can I find the privacy policy document?",
  createdAt: timestamp() - 52000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c16)
CREATE (c16)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c16)

// C17 — test on post 2
CREATE (c17:Comment {
  id: "seed-c17", content: "My experience has been average so far. The app loads quickly but I am still figuring out the layout.",
  createdAt: timestamp() - 50000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c17)
CREATE (c17)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c17)

// C18 — Mo45d on post 1
CREATE (c18:Comment {
  id: "seed-c18", content: "Noticed some minor UI inconsistencies on mobile. Not a big deal but worth mentioning to the dev team.",
  createdAt: timestamp() - 48000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c18)
CREATE (c18)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c18)

// C19 — user20 on post 1
CREATE (c19:Comment {
  id: "seed-c19", content: "Just created my account. The onboarding was straightforward. Let us see how it goes.",
  createdAt: timestamp() - 46000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c19)
CREATE (c19)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c19)

// C20 — test on post 1
CREATE (c20:Comment {
  id: "seed-c20", content: "Not sure what to post here yet. The feed algorithm seems to be learning my preferences slowly.",
  createdAt: timestamp() - 44000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c20)
CREATE (c20)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c20)

// ─────────────────────────────────────────────────────────────────────────────
// ── 4. NEGATIVE / TOXIC comments (various degrees) ────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

// C21 — Mo45d on post 1 — mild negative
CREATE (c21:Comment {
  id: "seed-c21", content: "This platform is honestly disappointing. The features are half-baked and support is completely unresponsive.",
  createdAt: timestamp() - 42000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c21)
CREATE (c21)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c21)

// C22 — user20 on post 2 — moderate negative
CREATE (c22:Comment {
  id: "seed-c22", content: "I regret joining this platform. Nothing works properly, the UI is a disaster and nobody cares about user feedback.",
  createdAt: timestamp() - 40000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c22)
CREATE (c22)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c22)

// C23 — test on post 3 — moderate negative, mild insult
CREATE (c23:Comment {
  id: "seed-c23", content: "The moderation rules are ridiculous. Whoever wrote them clearly has no clue what a healthy community looks like.",
  createdAt: timestamp() - 38000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c23)
CREATE (c23)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c23)

// C24 — Mo45d on post 3 — high negative, insult
CREATE (c24:Comment {
  id: "seed-c24", content: "This moderation team is absolutely useless. They ban innocent people while actual trolls run free. Pathetic management.",
  createdAt: timestamp() - 36000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c24)
CREATE (c24)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c24)

// C25 — user20 on post 1 — toxic, obscene
CREATE (c25:Comment {
  id: "seed-c25", content: "What a garbage platform full of idiots. The developers are incompetent morons who should never have touched a keyboard.",
  createdAt: timestamp() - 34000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c25)
CREATE (c25)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c25)

// C26 — test on post 2 — toxic, insult + threat undertone
CREATE (c26:Comment {
  id: "seed-c26", content: "People like the admin here deserve to have their platforms shut down. Keep pushing users away with your stupid policies.",
  createdAt: timestamp() - 32000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c26)
CREATE (c26)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c26)

// C27 — Mo45d on post 2 — high toxic, identity-based
CREATE (c27:Comment {
  id: "seed-c27", content: "I cannot stand these types of people always complaining and ruining every platform they join. They all act the same way.",
  createdAt: timestamp() - 30000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c27)
CREATE (c27)-[:TARGETS]->(p2)
CREATE (p2)-[:HAS_COMMENT]->(c27)

// C28 — user20 on post 3 — extreme toxic, severe insult
CREATE (c28:Comment {
  id: "seed-c28", content: "Whoever runs this community is a complete joke. I have never seen such incompetent, brain-dead management in my entire life.",
  createdAt: timestamp() - 28000000, ai_analyzed: false
})
CREATE (u1)-[:OWNS_COMMENT]->(c28)
CREATE (c28)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c28)

// C29 — test on post 3 — explicit threat
CREATE (c29:Comment {
  id: "seed-c29", content: "If this platform keeps banning people unfairly, someone is going to make sure the admins regret every single decision they made.",
  createdAt: timestamp() - 26000000, ai_analyzed: false
})
CREATE (u2)-[:OWNS_COMMENT]->(c29)
CREATE (c29)-[:TARGETS]->(p3)
CREATE (p3)-[:HAS_COMMENT]->(c29)

// C30 — Mo45d on post 1 — extreme, hate speech
CREATE (c30:Comment {
  id: "seed-c30", content: "This whole platform is a cesspool. The users here are the worst kind of people and the world would be better without them.",
  createdAt: timestamp() - 24000000, ai_analyzed: false
})
CREATE (u3)-[:OWNS_COMMENT]->(c30)
CREATE (c30)-[:TARGETS]->(p1)
CREATE (p1)-[:HAS_COMMENT]->(c30)

// ─────────────────────────────────────────────────────────────────────────────
// ── 5. Verify — run this separately after the above ──────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// MATCH (c:Comment) WHERE c.id STARTS WITH 'seed-'
// RETURN count(c) AS total_seeded
// Expected: 30
// ─────────────────────────────────────────────────────────────────────────────
