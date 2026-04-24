const express = require('express');
const neo4j = require('neo4j-driver');
require('dotenv').config();
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));

const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage: storage });

// NEO4J CONNECTION
const driver = neo4j.driver(
    'bolt://localhost:7687',
    neo4j.auth.basic(process.env.NEO4J_USER, process.env.NEO4J_PASSWORD)
);

app.get('/', (req, res) => res.send('TruthNet API Bridge: Active'));

// --- AUTHENTICATION ---

app.post('/api/auth/register', async (req, res) => {
    const { email, password, name, role } = req.body;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (u:User {email: $email}) RETURN u', { email });
        if (check.records.length > 0) return res.status(400).json({ success: false, message: "User exists" });

        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await session.run(
            `MERGE (r:Role {name: $roleName})
             CREATE (u:User {id: randomUUID(), email: $email, password: $hashedPassword, name: $name, status: "Active", bio: "INITIATING_BIOGRAPHY...", createdAt: timestamp()})
             CREATE (u)-[:HAS_ROLE]->(r)
             RETURN u, r.name as role`,
            { email, hashedPassword, name, roleName: role || "Member" }
        );
        res.json({ success: true, user: { ...result.records[0].get('u').properties, role: result.records[0].get('role') } });
    } catch (e) {
        console.error("DB Error:", e.message);
        res.status(500).json({ success: false, message: e.message });
    } finally { await session.close(); }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    const session = driver.session();
    try {
        const result = await session.run('MATCH (u:User {email: $email})-[:HAS_ROLE]->(r:Role) RETURN u, r.name as role', { email });
        if (result.records.length > 0) {
            const user = result.records[0].get('u').properties;
            if (await bcrypt.compare(password, user.password)) {
                res.json({ success: true, user: { ...user, role: result.records[0].get('role') } });
            } else res.status(401).json({ success: false, message: "INVALID_CREDENTIALS" });
        } else res.status(401).json({ success: false, message: "USER_NOT_FOUND" });
    } catch (e) {
        console.error("DB Error:", e.message);
        res.status(500).json({ success: false, message: e.message });
    } finally { await session.close(); }
});

// --- SETTINGS & ACCOUNT ---

app.put('/api/auth/update-password', async (req, res) => {
    const { userId, oldPassword, newPassword } = req.body;
    const session = driver.session();
    try {
        const result = await session.run('MATCH (u:User {id: $userId}) RETURN u', { userId });
        if (result.records.length === 0) return res.status(404).json({ success: false, message: "User not found" });

        const user = result.records[0].get('u').properties;
        const match = await bcrypt.compare(oldPassword, user.password);
        if (!match) return res.status(401).json({ success: false, message: "INCORRECT_OLD_PASSWORD" });

        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        await session.run('MATCH (u:User {id: $userId}) SET u.password = $hashedNewPassword', { userId, hashedNewPassword });
        res.json({ success: true });
    } catch (e) { res.status(500).send(e.message); }
    finally { await session.close(); }
});

app.put('/api/auth/update-email', async (req, res) => {
    const { userId, newEmail } = req.body;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (u:User {email: $newEmail}) RETURN u', { newEmail });
        if (check.records.length > 0) return res.status(400).json({ success: false, message: "EMAIL_ALREADY_IN_USE" });

        await session.run('MATCH (u:User {id: $userId}) SET u.email = $newEmail', { userId, newEmail });
        res.json({ success: true });
    } catch (e) { res.status(500).send(e.message); }
    finally { await session.close(); }
});

// --- PROFILE MANAGEMENT ---

app.get('/api/users/:userId/profile', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})
             OPTIONAL MATCH (u)-[:POSTED]->(p:Post) WHERE p.isDeleted IS NULL OR p.isDeleted = false
             OPTIONAL MATCH (u)-[:FOLLOWS]->(following)
             OPTIONAL MATCH (follower)-[:FOLLOWS]->(u)
             RETURN u,
                    count(DISTINCT p) as postCount,
                    count(DISTINCT following) as followingCount,
                    count(DISTINCT follower) as followerCount`,
            { userId }
        );
        if (result.records.length > 0) {
            const user = result.records[0].get('u').properties;
            res.json({
                ...user,
                postCount: result.records[0].get('postCount').toInt(),
                followingCount: result.records[0].get('followingCount').toInt(),
                followerCount: result.records[0].get('followerCount').toInt()
            });
        } else {
            res.status(404).json({ message: "USER_NOT_FOUND" });
        }
    } catch (e) { res.status(500).send(e.message); }
    finally { await session.close(); }
});

app.put('/api/users/:userId/profile', upload.single('avatar'), async (req, res) => {
    const { userId } = req.params;
    const { name, bio } = req.body;
    const avatarUrl = req.file ? `/uploads/${req.file.filename}` : undefined;

    const session = driver.session();
    try {
        let query = 'MATCH (u:User {id: $userId}) SET u.name = $name, u.bio = $bio';
        if (avatarUrl) query += ', u.avatar = $avatarUrl';
        query += ' RETURN u';

        const result = await session.run(query, { userId, name, bio, avatarUrl });
        res.json({ success: true, user: result.records[0].get('u').properties });
    } catch (e) { res.status(500).send(e.message); }
    finally { await session.close(); }
});

app.get('/api/users/:userId/posts', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:POSTED]->(p:Post)
             WHERE p.isDeleted IS NULL OR p.isDeleted = false
             RETURN u.name as author, p as post
             ORDER BY p.timestamp DESC`,
            { userId }
        );
        res.json(result.records.map(r => ({ author: r.get('author'), ...r.get('post').properties })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.get('/api/users/:userId/archive', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:POSTED]->(p:Post)
             WHERE p.isDeleted = true
             RETURN u.name as author, p as post
             ORDER BY p.timestamp DESC`,
            { userId }
        );
        res.json(result.records.map(r => ({ author: r.get('author'), ...r.get('post').properties })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

// --- POSTS ---

app.post('/api/posts', upload.single('media'), async (req, res) => {
    const { userId, content, location } = req.body;
    const isPublic = req.body.isPublic === 'true';
    const isVideo = req.body.isVideo === 'true';
    const mediaUrl = req.file ? `/uploads/${req.file.filename}` : null;

    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})
             CREATE (p:Post {id: randomUUID(), content: $content, mediaUrl: $mediaUrl, location: $location, isVideo: $isVideo, isPublic: $isPublic, isDeleted: false, timestamp: timestamp()})
             CREATE (u)-[:POSTED]->(p)
             RETURN p`,
            { userId, content, mediaUrl, location: location || null, isVideo, isPublic }
        );
        res.json(result.records[0].get('p').properties);
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.get('/api/feed', async (req, res) => {
    const userId = req.query.userId;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:POSTED]->(p:Post)
             WHERE p.isPublic = true AND (p.isDeleted IS NULL OR p.isDeleted = false)
             RETURN u.name as author, u.id as authorId, p as post,
                    COUNT { (p)<-[:LIKED]-() } as likeCount,
                    COUNT { (p)<-[:ON]-(:Comment) } as commentCount,
                    COUNT { (p)<-[:SHARED]-() } as shareCount,
                    EXISTS { (p)<-[:SAVED]-(:User {id: $userId}) } as isSaved,
                    EXISTS { (p)<-[:LIKED]-(:User {id: $userId}) } as isLiked
             ORDER BY p.timestamp DESC`,
            { userId: userId || "" }
        );
        res.json(result.records.map(r => ({
            author: r.get('author'),
            authorId: r.get('authorId'),
            ...r.get('post').properties,
            likeCount: r.get('likeCount').toInt(),
            commentCount: r.get('commentCount').toInt(),
            shareCount: r.get('shareCount').toInt(),
            isSaved: r.get('isSaved'),
            isLiked: r.get('isLiked')
        })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.put('/api/posts/:postId', async (req, res) => {
    const { postId } = req.params;
    const { userId, content } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:POSTED]->(p:Post {id: $postId})
             WHERE (p.isDeleted IS NULL OR p.isDeleted = false) AND p.timestamp > timestamp() - (24 * 60 * 60 * 1000)
             SET p.content = $content, p.isEdited = true, p.updatedAt = timestamp()
             RETURN p`,
            { postId, userId, content }
        );
        if (result.records.length > 0) {
            res.json({ success: true, post: result.records[0].get('p').properties });
        } else {
            res.status(403).json({ success: false, message: "EDIT_WINDOW_EXPIRED_OR_UNAUTHORIZED" });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/posts/:postId/archive', async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:POSTED]->(p:Post {id: $postId})
             SET p.isDeleted = true, p.deletedAt = timestamp()
             RETURN p`,
            { postId, userId }
        );
        if (result.records.length > 0) {
            res.json({ success: true });
        } else {
            res.status(403).json({ success: false, message: "UNAUTHORIZED_OR_NOT_FOUND" });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.delete('/api/posts/:postId/permanent', async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:POSTED]->(p:Post {id: $postId})
             DETACH DELETE p
             RETURN count(p) as deletedCount`,
            { postId, userId }
        );
        if (result.records[0].get('deletedCount').toInt() > 0) {
            res.json({ success: true });
        } else {
            res.status(403).json({ success: false, message: "UNAUTHORIZED_OR_NOT_FOUND" });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

// --- USERS SEARCH ---
app.get('/api/users/search', async (req, res) => {
    const { query } = req.query;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)
             WHERE toLower(u.name) CONTAINS toLower($query)
             RETURN u.name as name, u.id as id LIMIT 5`,
            { query: query || "" }
        );
        res.json(result.records.map(r => ({ name: r.get('name'), id: r.get('id') })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

// --- INTERACTIONS ---

app.post('/api/posts/like', async (req, res) => {
    const { userId, postId } = req.body;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (u:User {id: $userId})-[l:LIKED]->(p:Post {id: $postId}) RETURN l', { userId, postId });
        if (check.records.length > 0) {
            await session.run('MATCH (u:User {id: $userId})-[l:LIKED]->(p:Post {id: $postId}) DELETE l', { userId, postId });
            res.json({ success: true, action: 'unliked' });
        } else {
            await session.run('MATCH (u:User {id: $userId}), (p:Post {id: $postId}) MERGE (u)-[:LIKED]->(p)', { userId, postId });
            res.json({ success: true, action: 'liked' });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/posts/share', async (req, res) => {
    const { userId, postId } = req.body;
    const session = driver.session();
    try {
        await session.run('MATCH (u:User {id: $userId}), (p:Post {id: $postId}) MERGE (u)-[:SHARED]->(p)', { userId, postId });
        res.json({ success: true });
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/posts/save', async (req, res) => {
    const { userId, postId } = req.body;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (u:User {id: $userId})-[s:SAVED]->(p:Post {id: $postId}) RETURN s', { userId, postId });
        if (check.records.length > 0) {
            await session.run('MATCH (u:User {id: $userId})-[s:SAVED]->(p:Post {id: $postId}) DELETE s', { userId, postId });
            res.json({ success: true, action: 'unsaved' });
        } else {
            await session.run('MATCH (u:User {id: $userId}), (p:Post {id: $postId}) MERGE (u)-[:SAVED]->(p)', { userId, postId });
            res.json({ success: true, action: 'saved' });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/posts/comment', async (req, res) => {
    const { userId, postId, content } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId}), (p:Post {id: $postId})
             CREATE (c:Comment {id: randomUUID(), content: $content, timestamp: timestamp()})
             CREATE (u)-[:COMMENTED]->(c)-[:ON]->(p)
             RETURN c`,
            { userId, postId, content }
        );
        res.json({ success: true, comment: result.records[0].get('c').properties });
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.get('/api/posts/:postId/comments', async (req, res) => {
    const { postId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:COMMENTED]->(c:Comment)-[:ON]->(p:Post {id: $postId})
             RETURN u.name as author, c as comment,
                    COUNT { (c)<-[:LIKED]-() } as likeCount,
                    COUNT { (c)<-[:REPLIED_TO]-(:Comment) } as replyCount
             ORDER BY c.timestamp ASC`,
            { postId }
        );
        res.json(result.records.map(r => ({
            author: r.get('author'),
            ...r.get('comment').properties,
            likeCount: r.get('likeCount').toInt(),
            replyCount: r.get('replyCount').toInt()
        })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

// --- COMMENT INTERACTIONS ---

app.post('/api/comments/:commentId/like', async (req, res) => {
    const { userId } = req.body;
    const { commentId } = req.params;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (u:User {id: $userId})-[l:LIKED]->(c:Comment {id: $commentId}) RETURN l', { userId, commentId });
        if (check.records.length > 0) {
            await session.run('MATCH (u:User {id: $userId})-[l:LIKED]->(c:Comment {id: $commentId}) DELETE l', { userId, commentId });
            res.json({ success: true, action: 'unliked' });
        } else {
            await session.run('MATCH (u:User {id: $userId}), (c:Comment {id: $commentId}) MERGE (u)-[:LIKED]->(c)', { userId, commentId });
            res.json({ success: true, action: 'liked' });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/comments/:commentId/reply', async (req, res) => {
    const { userId, content } = req.body;
    const { commentId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId}), (target:Comment {id: $commentId})
             CREATE (reply:Comment {id: randomUUID(), content: $content, timestamp: timestamp()})
             CREATE (u)-[:COMMENTED]->(reply)-[:REPLIED_TO]->(target)
             RETURN reply`,
            { userId, commentId, content }
        );
        res.json({ success: true, reply: result.records[0].get('reply').properties });
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.get('/api/comments/:commentId/replies', async (req, res) => {
    const { commentId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:COMMENTED]->(reply:Comment)-[:REPLIED_TO]->(target:Comment {id: $commentId})
             RETURN u.name as author, reply,
                    COUNT { (reply)<-[:LIKED]-() } as likeCount,
                    COUNT { (reply)<-[:REPLIED_TO]-(:Comment) } as replyCount
             ORDER BY reply.timestamp ASC`,
            { commentId }
        );
        res.json(result.records.map(r => ({
            author: r.get('author'),
            ...r.get('reply').properties,
            likeCount: r.get('likeCount').toInt(),
            replyCount: r.get('replyCount').toInt()
        })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

// --- Admin

app.post('/api/auth/admin/register', async (req, res) => {
    const { email, password, name, username, role } = req.body;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (u:User {email: $email}) RETURN u', { email });
        if (check.records.length > 0) return res.status(400).json({ success: false, message: "User exists" });

        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await session.run(
            `MERGE (r:Role {name: $roleName})
             CREATE (u:User {id: randomUUID(), email: $email, password: $hashedPassword, name: $name, username: $username,  status: "Active", bio: "INITIATING_BIOGRAPHY...", createdAt: timestamp()})
             CREATE (u)-[:HAS_ROLE]->(r)
             RETURN u, r.name as role`,
            { email, hashedPassword, name, username, roleName: role || "Member" }
        );
        res.json({ success: true, user: { ...result.records[0].get('u').properties, role: result.records[0].get('role') } });
    } catch (e) {
        console.error("DB Error:", e.message);
        res.status(500).json({ success: false, message: e.message });
    } finally { await session.close(); }
});



// --- Moderator

//get all moderators
app.get('/api/admin/moderators', async (req, res) => {
    const session = driver.session();

    try {
        const result = await session.run(`
            MATCH (u:User)-[:HAS_ROLE]->(r:Role {name: "Moderator"})
            RETURN u, r.name as role
        `);

        const moderators = result.records.map(r => ({
            ...r.get('u').properties,
            role: r.get('role')
        }));

        res.json(moderators);

    } catch (e) {
        res.status(500).json([]);
    } finally {
        await session.close();
    }
});

// add moderator
app.post('/api/admin/moderators', async (req, res) => {
    const { name, username, email, password, status, role } = req.body;
    const session = driver.session();

    try {
        const hashedPassword = await bcrypt.hash(password, 10);

        const result = await session.run(`
            MERGE (r:Role {name: "Moderator"})
            CREATE (u:User {
                id: randomUUID(),
                name: $name,
                username: $username,
                email: $email,
                password: $password,
                status: $status,
                createdAt: timestamp()
            })
            CREATE (u)-[:HAS_ROLE]->(r)
            RETURN u
        `, {
            name, username, email,
            password: hashedPassword,
            status
        });

        res.json({ success: true });

    } catch (e) {
        res.status(500).json({ success: false });
    } finally {
        await session.close();
    }
});

//update moderator
app.put('/api/admin/moderators/:id', async (req, res) => {
    const { id } = req.params;
    const data = req.body;

    const session = driver.session();

    try {
        await session.run(`
            MATCH (u:User {id: $id})
            SET u.name = $name,
                u.username = $username,
                u.email = $email,
                u.status = $status
        `, { id, ...data });

        res.json({ success: true });

    } catch (e) {
        res.status(500).json({ success: false });
    } finally {
        await session.close();
    }
});

//delete moderator
app.delete('/api/admin/moderators/:id', async (req, res) => {
    const { id } = req.params;
    const session = driver.session();

    try {
        await session.run(`
            MATCH (u:User {id: $id})
            DETACH DELETE u
        `, { id });

        res.json({ success: true });

    } catch (e) {
        res.status(500).json({ success: false });
    } finally {
        await session.close();
    }
});

// add role
app.post('/api/admin/roles', async (req, res) => {
  const { name, description } = req.body;
  const session = driver.session();

  try {
    await session.run(`
      CREATE (r:Role {
        id: randomUUID(),
        name: $name,
        description: $description
      })
    `, { name, description });

    res.json({ success: true });
  } finally {
    await session.close();
  }
});

//delete role
app.delete('/api/admin/roles/:id', async (req, res) => {
  const { id } = req.params;
  const session = driver.session();

  try {
    await session.run(`
      MATCH (r:Role {id: $id})
      DETACH DELETE r
    `, { id });

    res.json({ success: true });
  } finally {
    await session.close();
  }
});

// get roles
app.get('/api/admin/roles', async (req, res) => {
  const session = driver.session();
  try {
    const result = await session.run(`MATCH (r:Role) RETURN r`);

    const roles = result.records.map(r => ({
      id: r.get('r').identity.toString(),
      ...r.get('r').properties
    }));

    res.json(roles);
  } finally {
    await session.close();
  }
});

//global metrics
app.get('/api/admin/dashboard', async (req, res) => {
    const session = driver.session();

    try {
        const result = await session.run(`
            MATCH (u:User)
            WITH count(u) as users

            MATCH (p:Post)
            WITH users, count(p) as posts

            MATCH (c:Comment)
            WITH users, posts, count(c) as comments

            RETURN users, posts, comments
        `);

        const record = result.records[0];

        res.json({
            users: record.get('users').toInt(),
            posts: record.get('posts').toInt(),
            comments: record.get('comments').toInt()
        });

    } catch (e) {
        res.status(500).json({});
    } finally {
        await session.close();
    }
});

//posts per day
app.get('/api/admin/stats/posts-per-day', async (req, res) => {
    const session = driver.session();

    try {
        const result = await session.run(`
            MATCH (p:Post)
            RETURN date(datetime({epochMillis: p.timestamp})) as day,
                   count(p) as count
            ORDER BY day
        `);

        res.json(result.records.map(r => ({
            day: r.get('day'),
            count: r.get('count').toInt()
        })));

    } catch (e) {
        res.status(500).json([]);
    } finally {
        await session.close();
    }
});





app.listen(3000, () => console.log('Backend listening on port 3000'));
