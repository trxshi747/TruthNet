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
// !!! disclaimer , I changed this function to match the appropriate format
/*
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
*/

// POST /api/auth/register - Final version with conditional profile and unique username
app.post('/api/auth/register', async (req, res) => {
  const { email, password, firstName, lastName, username, role } = req.body;

  // Username validation: Alphanumeric only
  const usernameRegex = /^[a-zA-Z0-9]+$/;
  if (!usernameRegex.test(username)) {
    return res.status(400).json({ 
      success: false, 
      message: "USERNAME_INVALID_SYMBOLS_DETECTED" 
    });
  }

  // Password validation: 8+ chars, letters and numbers
  const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d).{8,}$/;
  if (!passwordRegex.test(password)) {
    return res.status(400).json({ 
      success: false, 
      message: "PASSWORD_TOO_WEAK_OR_TOO_SHORT" 
    });
  }

  const session = driver.session();
  try {
    // Check for existing email or username
    const check = await session.run(
      'MATCH (u:User) WHERE u.email = $email OR u.username = $username RETURN u.email AS email, u.username AS username', 
      { email, username }
    );
    if (check.records.length > 0) {
        const existing = check.records[0];
        if (existing.get('email') === email) {
            return res.status(400).json({ success: false, field: 'email', message: "EMAIL_EXISTS" });
        }
        if (existing.get('username') === username) {
            return res.status(400).json({ success: false, field: 'username', message: "USERNAME_TAKEN" });
        }
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const targetRole = role || "Member";
    const isStandardUser = targetRole === "Member";

    let result;
    if (isStandardUser) {
        result = await session.run(`
          MERGE (r:Role {name: $roleName})
          CREATE (u:User:AuthenticatedUser {
            id:               randomUUID(),
            firstName:        $firstName,
            lastName:         $lastName,
            username:         $username,
            email:            $email,
            password:         $hashedPassword,
            status:           'ACTIVE',
            registrationDate: timestamp()
          })
          CREATE (p:Profile {
            id:              randomUUID(),
            bio:             '',
            avatar:          null,
            privacyLevel:    'public',
            followerCount:   0,
            followingCount:  0
          })
          CREATE (u)-[:HAS_ROLE]->(r)
          CREATE (u)-[:HAS_PROFILE]->(p)
          RETURN u, r.name as role
        `, { email, hashedPassword, firstName, lastName, username, roleName: targetRole });
    } else {
        const userLabel = targetRole === "Admin" ? "Administrator" : "Moderator";
        result = await session.run(`
          MERGE (r:Role {name: $roleName})
          CREATE (u:User:${userLabel} {
            id:               randomUUID(),
            firstName:        $firstName,
            lastName:         $lastName,
            username:         $username,
            email:            $email,
            password:         $hashedPassword,
            status:           'ACTIVE',
            registrationDate: timestamp()
          })
          CREATE (u)-[:HAS_ROLE]->(r)
          RETURN u, r.name as role
        `, { email, hashedPassword, firstName, lastName, username, roleName: targetRole });
    }

    const user = result.records[0].get('u').properties;
    res.json({
      success: true,
      user: { ...user, role: result.records[0].get('role') }
    });

  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  } finally {
    await session.close();
  }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body; // Keeping field name 'email' for compatibility, but using it as identifier
    const session = driver.session();
    try {
        const result = await session.run(
            'MATCH (u:User) WHERE u.email = $email OR u.username = $email ' +
            'MATCH (u)-[:HAS_ROLE]->(r:Role) RETURN u, r.name as role', 
            { email }
        );
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

    // Password validation: 8+ chars, letters and numbers
    const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(newPassword)) {
        return res.status(400).json({ 
            success: false, 
            message: "PASSWORD_TOO_WEAK_OR_TOO_SHORT" 
        });
    }

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

// I just changed the place of those functions , since it is advised to have the static routes first

app.post('/api/auth/admin/register', async (req, res) => {
    const { email, password, firstName, lastName, username, role } = req.body;

    // Username validation: Alphanumeric only
    const usernameRegex = /^[a-zA-Z0-9]+$/;
    if (!usernameRegex.test(username)) {
        return res.status(400).json({ 
            success: false, 
            message: "USERNAME_INVALID_SYMBOLS_DETECTED" 
        });
    }

    // Password validation: 8+ chars, letters and numbers
    const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(password)) {
        return res.status(400).json({ 
            success: false, 
            message: "PASSWORD_TOO_WEAK_OR_TOO_SHORT" 
        });
    }

    const session = driver.session();
    try {
        // Check for existing email or username
        const check = await session.run(
            'MATCH (u:User) WHERE u.email = $email OR u.username = $username RETURN u.email AS email, u.username AS username', 
            { email, username }
        );
        if (check.records.length > 0) {
            const existing = check.records[0];
            if (existing.get('email') === email) {
                return res.status(400).json({ success: false, field: 'email', message: "EMAIL_EXISTS" });
            }
            if (existing.get('username') === username) {
                return res.status(400).json({ success: false, field: 'username', message: "USERNAME_TAKEN" });
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await session.run(
            `MERGE (r:Role {name: $roleName})
             CREATE (u:User:AuthenticatedUser:Administrator {
                id: randomUUID(), 
                email: $email, 
                password: $hashedPassword, 
                firstName: $firstName, 
                lastName: $lastName, 
                username: $username,  
                status: "ACTIVE", 
                registrationDate: timestamp()
             })
             CREATE (u)-[:HAS_ROLE]->(r)
             RETURN u, r.name as role`,
            { email, hashedPassword, firstName, lastName, username, roleName: role || "Admin" }
        );
        res.json({ success: true, user: { ...result.records[0].get('u').properties, role: result.records[0].get('role') } });
    } catch (e) {
        console.error("DB Error:", e.message);
        res.status(500).json({ success: false, message: e.message });
    } finally { await session.close(); }
});

app.get('/api/feed', async (req, res) => {
    const userId = req.query.userId;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:OWNS_POST]->(p:Post)
             WHERE p.visibility = 'public' AND (p.isDeleted IS NULL OR p.isDeleted = false)
             RETURN u.username as author, u.id as authorId, p as post,
                    COUNT { (p)<-[:HAS_REACTION]-() } as likeCount,
                    COUNT { (p)<-[:HAS_COMMENT]-() } as commentCount,
                    COUNT { (p)<-[:SHARED]-() } as shareCount,
                    EXISTS { (p)<-[:SAVED]-(:User {id: $userId}) } as isSaved,
                    EXISTS { (p)<-[:HAS_REACTION]-(r:Reaction {targetType: 'Post'})<-[:OWNS_REACTION]-(:User {id: $userId}) } as isLiked
             ORDER BY p.createdAt DESC`,
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

app.get('/api/users/search', async (req, res) => {
    const { query } = req.query;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)
             WHERE toLower(u.username) CONTAINS toLower($query)
             RETURN u.username as name, u.id as id LIMIT 5`,
            { query: query || "" }
        );
        res.json(result.records.map(r => ({ name: r.get('name'), id: r.get('id') })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});


app.post('/api/posts/like', async (req, res) => {
    const { userId, postId } = req.body;
    const session = driver.session();
    try {
        const check = await session.run(
            'MATCH (u:User {id: $userId})-[:OWNS_REACTION]->(r:Reaction {targetType: "Post"})-[:TARGETS]->(p:Post {id: $postId}) RETURN r',
            { userId, postId }
        );
        
        if (check.records.length > 0) {
            await session.run(
                'MATCH (u:User {id: $userId})-[:OWNS_REACTION]->(r:Reaction {targetType: "Post"})-[:TARGETS]->(p:Post {id: $postId}) DETACH DELETE r',
                { userId, postId }
            );
            res.json({ success: true, action: 'unliked' });
        } else {
            await session.run(`
                MATCH (u:User {id: $userId})
                MATCH (p:Post {id: $postId})
                CREATE (r:Reaction {
                    id: randomUUID(),
                    type: 'LIKE',
                    targetType: 'Post',
                    createdAt: timestamp()
                })
                CREATE (u)-[:OWNS_REACTION]->(r)
                CREATE (r)-[:TARGETS]->(p)
                CREATE (r)-[:HAS_REACTION]->(p)
            `, { userId, postId });
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

// --- Admin Dashboard Metrics ---
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

// --- PROFILE MANAGEMENT ---

app.get('/api/users/:userId/profile', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        // Check if user is an admin or moderator first
        const roleResult = await session.run(
            `MATCH (u:User {id: $userId})-[:HAS_ROLE]->(r:Role)
             WHERE r.name IN ['Admin', 'Moderator']
             RETURN u, r.name as role`,
            { userId }
        );

        if (roleResult.records.length > 0) {
            const user = roleResult.records[0].get('u').properties;
            const role = roleResult.records[0].get('role');
            return res.json({ ...user, role, hasProfile: false });
        }

        // Standard user with a profile
        const profileResult = await session.run(
            `MATCH (u:User {id: $userId})-[:HAS_PROFILE]->(profile:Profile)
             OPTIONAL MATCH (u)-[:OWNS_POST]->(p:Post) WHERE p.isDeleted IS NULL OR p.isDeleted = false
             OPTIONAL MATCH (profile)-[:HAS_FOLLOWING]->(following:Following)
             OPTIONAL MATCH (profile)-[:HAS_FOLLOWER]->(follower:Follower)
             RETURN u, profile,
                    count(DISTINCT p) as postCount,
                    count(DISTINCT following) as followingCount,
                    count(DISTINCT follower) as followerCount`,
            { userId }
        );
        if (profileResult.records.length > 0) {
            const user = profileResult.records[0].get('u').properties;
            const profile = profileResult.records[0].get('profile').properties;
            res.json({
                ...user,
                ...profile,
                postCount: profileResult.records[0].get('postCount').toInt(),
                followingCount: profileResult.records[0].get('followingCount').toInt(),
                followerCount: profileResult.records[0].get('followerCount').toInt(),
                hasProfile: true
            });
        } else {
            res.status(404).json({ message: "USER_OR_PROFILE_NOT_FOUND" });
        }
    } catch (e) { res.status(500).send(e.message); }
    finally { await session.close(); }
});

app.put('/api/users/:userId/profile', upload.single('avatar'), async (req, res) => {
    const { userId } = req.params;
    const { firstName, lastName, bio } = req.body;
    const avatarUrl = req.file ? `/uploads/${req.file.filename}` : undefined;

    const session = driver.session();
    try {
        let query = 'MATCH (u:User {id: $userId})-[:HAS_PROFILE]->(p:Profile) SET u.firstName = $firstName, u.lastName = $lastName, p.bio = $bio';
        if (avatarUrl) query += ', p.avatar = $avatarUrl';
        query += ' RETURN u, p';

        const result = await session.run(query, { userId, firstName, lastName, bio, avatarUrl });
        res.json({ success: true, user: result.records[0].get('u').properties, profile: result.records[0].get('p').properties });
    } catch (e) { res.status(500).send(e.message); }
    finally { await session.close(); }
});

app.get('/api/users/:userId/posts', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:OWNS_POST]->(p:Post)
             WHERE p.isDeleted IS NULL OR p.isDeleted = false
             RETURN u.username as author, p as post
             ORDER BY p.createdAt DESC`,
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
            `MATCH (u:User {id: $userId})-[:OWNS_POST]->(p:Post)
             WHERE p.isDeleted = true
             RETURN u.username as author, p as post
             ORDER BY p.createdAt DESC`,
            { userId }
        );
        res.json(result.records.map(r => ({ author: r.get('author'), ...r.get('post').properties })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

// --- POSTS ---

app.post('/api/posts', upload.array('media', 10), async (req, res) => {
    const { userId, content, location } = req.body;
    const visibility = req.body.isPublic === 'true' ? 'public' : 'private';
    const isVideo = req.body.isVideo === 'true';

    // Handle multiple files
    const mediaUrls = req.files ? req.files.map(file => `/uploads/${file.filename}`) : [];

    // Protocol Check: Strictly MP4 for videos
    if (isVideo) {
      const invalidFiles = req.files ? req.files.filter(f => !f.originalname.toLowerCase().endsWith('.mp4')) : [];
      if (invalidFiles.length > 0) {
        return res.status(400).json({ success: false, message: "PROTOCOL_VIOLATION: ONLY_MP4_ALLOWED" });
      }
    }

    // Maintain mediaUrl field for backward compatibility (first image)
    const primaryMediaUrl = mediaUrls.length > 0 ? mediaUrls[0] : null;

    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})
             CREATE (p:Post {
                id: randomUUID(),
                content: $content,
                mediaUrl: $primaryMediaUrl,
                mediaUrls: $mediaUrls,
                location: $location,
                isVideo: $isVideo,
                visibility: $visibility,
                isDeleted: false,
                createdAt: timestamp()
             })
             CREATE (u)-[:OWNS_POST]->(p)
             RETURN p`,
            { userId, content, primaryMediaUrl, mediaUrls, location: location || null, isVideo, visibility }
        );
        res.json(result.records[0].get('p').properties);
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

// --- USERS SEARCH ---

app.put('/api/posts/:postId', async (req, res) => {
    const { postId } = req.params;
    const { userId, content } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:OWNS_POST]->(p:Post {id: $postId})
             WHERE (p.isDeleted IS NULL OR p.isDeleted = false) AND p.createdAt > timestamp() - (24 * 60 * 60 * 1000)
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
            `MATCH (u:User {id: $userId})-[:OWNS_POST]->(p:Post {id: $postId})
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
            `MATCH (u:User {id: $userId})-[:OWNS_POST]->(p:Post {id: $postId})
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


// --- INTERACTIONS ---


app.get('/api/posts/:postId/comments', async (req, res) => {
    const { postId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:OWNS_COMMENT]->(c:Comment)-[:TARGETS]->(p:Post {id: $postId})
             RETURN u.username as author, u.id as authorId, c as comment,
                    COUNT { (c)<-[:HAS_REACTION]-() } as likeCount,
                    COUNT { (c)<-[:REPLIED_TO]-(:Comment) } as replyCount
             ORDER BY c.createdAt ASC`,
            { postId }
        );
        res.json(result.records.map(r => ({
            author: r.get('author'),
            authorId: r.get('authorId'),
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
        const check = await session.run(
            'MATCH (u:User {id: $userId})-[:OWNS_REACTION]->(r:Reaction {targetType: "Comment"})-[:TARGETS]->(c:Comment {id: $commentId}) RETURN r',
            { userId, commentId }
        );
        if (check.records.length > 0) {
            await session.run(
                'MATCH (u:User {id: $userId})-[:OWNS_REACTION]->(r:Reaction {targetType: "Comment"})-[:TARGETS]->(c:Comment {id: $commentId}) DETACH DELETE r',
                { userId, commentId }
            );
            res.json({ success: true, action: 'unliked' });
        } else {
            await session.run(`
                MATCH (u:User {id: $userId})
                MATCH (c:Comment {id: $commentId})
                CREATE (r:Reaction {
                    id: randomUUID(),
                    type: 'LIKE',
                    targetType: 'Comment',
                    createdAt: timestamp()
                })
                CREATE (u)-[:OWNS_REACTION]->(r)
                CREATE (r)-[:TARGETS]->(c)
                CREATE (r)-[:HAS_REACTION]->(c)
            `, { userId, commentId });
            res.json({ success: true, action: 'liked' });
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
             CREATE (c:Comment {id: randomUUID(), content: $content, createdAt: timestamp()})
             CREATE (u)-[:OWNS_COMMENT]->(c)
             CREATE (c)-[:TARGETS]->(p)
             CREATE (p)-[:HAS_COMMENT]->(c)
             RETURN c`,
            { userId, postId, content }
        );
        res.json({ success: true, comment: result.records[0].get('c').properties });
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
             CREATE (reply:Comment {id: randomUUID(), content: $content, createdAt: timestamp()})
             CREATE (u)-[:OWNS_COMMENT]->(reply)
             CREATE (reply)-[:REPLIED_TO]->(target)
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
            `MATCH (u:User)-[:OWNS_COMMENT]->(reply:Comment)-[:REPLIED_TO]->(target:Comment {id: $commentId})
             RETURN u.username as author, u.id as authorId, reply,
                    COUNT { (reply)<-[:HAS_REACTION]-() } as likeCount,
                    COUNT { (reply)<-[:REPLIED_TO]-(:Comment) } as replyCount
             ORDER BY reply.createdAt ASC`,
            { commentId }
        );
        res.json(result.records.map(r => ({
            author: r.get('author'),
            authorId: r.get('authorId'),
            ...r.get('reply').properties,
            likeCount: r.get('likeCount').toInt(),
            replyCount: r.get('replyCount').toInt()
        })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.put('/api/comments/:commentId', async (req, res) => {
    const { commentId } = req.params;
    const { userId, content } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:OWNS_COMMENT]->(c:Comment {id: $commentId})
             SET c.content = $content, c.isEdited = true, c.updatedAt = timestamp()
             RETURN c`,
            { commentId, userId, content }
        );
        if (result.records.length > 0) {
            res.json({ success: true, comment: result.records[0].get('c').properties });
        } else {
            res.status(403).json({ success: false, message: "UNAUTHORIZED_OR_NOT_FOUND" });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.delete('/api/comments/:commentId', async (req, res) => {
    const { commentId } = req.params;
    const { userId } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})-[:OWNS_COMMENT]->(c:Comment {id: $commentId})
             DETACH DELETE c
             RETURN count(c) as deletedCount`,
            { commentId, userId }
        );
        if (result.records[0].get('deletedCount').toInt() > 0) {
            res.json({ success: true });
        } else {
            res.status(403).json({ success: false, message: "UNAUTHORIZED_OR_NOT_FOUND" });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

// --- Admin

// -- Users

app.get('/api/admin/users', async (req, res) => {
    const session = driver.session();
    try {
        const result = await session.run(`
            MATCH (u:User)-[:HAS_ROLE]->(r:Role {name: 'Member'})
            OPTIONAL MATCH (u)-[:HAS_PROFILE]->(p:Profile)
            OPTIONAL MATCH (u)-[:HAS_SANCTION]->(s:Sanction {status: 'ACTIVE'})
            RETURN
                u.id                AS id,
                u.firstName         AS firstName,
                u.lastName          AS lastName,
                u.username          AS username,
                u.email             AS email,
                u.status            AS status,
                u.registrationDate  AS registrationDate,
                r.name              AS role,
                p.bio               AS bio,
                p.avatar            AS avatar,
                s.id                AS sanctionId,
                s.type              AS sanctionType,
                s.reason            AS sanctionReason,
                s.endDate           AS sanctionEndDate
        `);

        const users = result.records.map(record => {
            const raw = {
                id:        record.get('id'),
                firstName: record.get('firstName'),
                lastName:  record.get('lastName'),
                username:  record.get('username'),
                email:     record.get('email'),
                status:    record.get('status'),
                registrationDate: record.get('registrationDate'),
                role:      record.get('role'),
                bio:       record.get('bio'),
                avatar:    record.get('avatar'),
                sanctionId:   record.get('sanctionId'),
                sanctionType: record.get('sanctionType'),
                sanctionReason: record.get('sanctionReason'),
                sanctionEndDate: record.get('sanctionEndDate'),
            };

            return {
                id:       raw.id,
                firstName: raw.firstName ?? 'Unknown',
                lastName:  raw.lastName ?? '',
                username: raw.username,
                email:    raw.email ?? '',
                status:   (raw.status ?? 'ACTIVE').toUpperCase(),
                registrationDate: raw.registrationDate ?? null,
                role:     raw.role ?? 'Member',
                profile: {
                    bio:    raw.bio ?? '',
                    avatar: raw.avatar ?? null,
                },
                activeSanction: raw.sanctionId ? {
                    id:      raw.sanctionId,
                    type:    raw.sanctionType,
                    reason:  raw.sanctionReason,
                    endDate: raw.sanctionEndDate,
                } : null,
            };
        });

        res.json(users);

    } catch (error) {
        console.error('❌ /api/admin/users error:', error.message);
        res.status(500).json({ error: error.message });
    } finally {
        await session.close();
    }
});

// Sanction corrigée avec les bons noms de champs
app.put('/api/admin/users/:userId/suspend', async (req, res) => {
  const { userId } = req.params;
  const { reason, durationDays, adminId } = req.body;
  const session = driver.session();

  const sanctionId = require('crypto').randomUUID();
  const startDate  = new Date().toISOString();
  const endDate    = new Date(
    Date.now() + durationDays * 24 * 60 * 60 * 1000
  ).toISOString();

  try {
    await session.run(`
      MATCH (u:User {id: $userId})
      CREATE (s:Sanction {
        id:            $sanctionId,
        type:          'SUSPENDED',
        reason:        $reason,
        startDate:     $startDate,
        endDate:       $endDate,
        status:        'ACTIVE',
        createdBy:     $adminId,
        createdAt:     timestamp()
      })
      CREATE (u)-[:HAS_SANCTION]->(s)
      SET u.status = 'SUSPENDED',
          u.activeSanctionId = $sanctionId
      RETURN u, s
    `, { userId, sanctionId, reason, startDate, endDate, adminId });

    res.json({ success: true, sanctionId });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  } finally {
    await session.close();
  }
});

// BAN a user (permanent)
app.put('/api/admin/users/:userId/ban', async (req, res) => {
    const { userId } = req.params;
    const { reason, adminId } = req.body;

    if (!reason) {
        return res.status(400).json({
            success: false,
            message: "Reason is required"
        });
    }

    const session = driver.session();
    const sanctionId = require('crypto').randomUUID();
    const startDate = new Date().toISOString();

    try {
        await session.run(
            `MATCH (u:User {id: $userId})
             CREATE (s:Sanction {
                id: $id,
                type: 'BAN',
                reason: $reason,
                startDate: $startDate,
                status: 'ACTIVE',
                createdBy: $adminId,
                createdAt: timestamp()
            })
            CREATE (u)-[:HAS_SANCTION]->(s)
            SET u.status = 'BANNED',
                u.activeSanctionId = $id
            RETURN u, s`,
            {
                id: sanctionId,
                userId,
                reason,
                startDate,
                adminId
            }
        );

        res.json({
            success: true,
            message: "User banned permanently",
            sanctionId: sanctionId
        });

    } catch (error) {
        console.error('Ban error:', error);
        res.status(500).json({ success: false, message: error.message });
    } finally {
        await session.close();
    }
});

// REVOKE a sanction (lift suspension or ban)
app.put('/api/admin/sanctions/:sanctionId/revoke', async (req, res) => {
    const { sanctionId } = req.params;
    const { adminId } = req.body;

    const session = driver.session();

    try {
        // 1. Get sanction details
        const sanctionResult = await session.run(
            `MATCH (s:Sanction {id: $sanctionId})<-[:HAS_SANCTION]-(u:User)
             RETURN u.id as userId, s.type as type`,
            { sanctionId }
        );

        if (sanctionResult.records.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Sanction not found"
            });
        }

        const userId = sanctionResult.records[0].get('userId');

        // 2. Update sanction status
        await session.run(
            `MATCH (s:Sanction {id: $sanctionId})
             SET s.status = 'REVOKED',
                 s.revokedBy = $adminId,
                 s.revokedAt = timestamp()
             RETURN s`,
            { sanctionId, adminId }
        );

        // 3. Reactivate user
        await session.run(
            `MATCH (u:User {id: $userId})
             SET u.status = 'ACTIVE',
                 u.activeSanctionId = null
             RETURN u`,
            { userId }
        );

        res.json({
            success: true,
            message: "Sanction revoked successfully"
        });

    } catch (error) {
        console.error('Revoke error:', error);
        res.status(500).json({ success: false, message: error.message });
    } finally {
        await session.close();
    }
});

// DEACTIVATE user (without sanction record - soft deactivation)
app.put('/api/admin/users/:userId/deactivate', async (req, res) => {
    const { userId } = req.params;

    const session = driver.session();

    try {
        await session.run(
            `MATCH (u:User {id: $userId})
             SET u.status = 'INACTIVE'
             RETURN u`,
            { userId }
        );

        res.json({
            success: true,
            message: "User deactivated successfully"
        });

    } catch (error) {
        console.error('Deactivate error:', error);
        res.status(500).json({ success: false, message: error.message });
    } finally {
        await session.close();
    }
});

// ACTIVATE a user (reactivate)
app.put('/api/admin/users/:userId/activate', async (req, res) => {
    const { userId } = req.params;

    const session = driver.session();

    try {
        await session.run(
            `MATCH (u:User {id: $userId})
             SET u.status = 'ACTIVE'
             RETURN u`,
            { userId }
        );

        res.json({
            success: true,
            message: "User activated successfully"
        });

    } catch (error) {
        console.error('Activate error:', error);
        res.status(500).json({ success: false, message: error.message });
    } finally {
        await session.close();
    }
});

// DELETE user permanently
app.delete('/api/admin/users/:userId', async (req, res) => {
    const { userId } = req.params;

    const session = driver.session();

    try {
        // Delete user and all relationships
        await session.run(
            `MATCH (u:User {id: $userId})
             DETACH DELETE u`,
            { userId }
        );

        res.json({
            success: true,
            message: "User deleted permanently"
        });

    } catch (error) {
        console.error('Delete error:', error);
        res.status(500).json({ success: false, message: error.message });
    } finally {
        await session.close();
    }
});

// GET all active sanctions
app.get('/api/admin/sanctions/active', async (req, res) => {
    const session = driver.session();

    try {
        const result = await session.run(`
            MATCH (u:User)-[:HAS_SANCTION]->(s:Sanction {status: 'ACTIVE'})
            RETURN u, s
            ORDER BY s.startDate DESC
        `);

        const sanctions = result.records.map(record => {
            const user = record.get('u').properties;
            const sanction = record.get('s').properties;

            return {
                sanction: {
                    id: sanction.id,
                    type: sanction.type,
                    reason: sanction.reason,
                    startDate: sanction.startDate,
                    endDate: sanction.endDate,
                    status: sanction.status,
                    createdBy: sanction.createdBy
                },
                user: {
                    id: user.id,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    email: user.email,
                    username: user.username
                }
            };
        });

        res.json(sanctions);

    } catch (error) {
        console.error('Get sanctions error:', error);
        res.status(500).json([]);
    } finally {
        await session.close();
    }
});

// Auto-lift expired suspensions (run this every hour)
async function autoLiftExpiredSuspensions() {
    const session = driver.session();

    try {
        const now = new Date().toISOString();

        const expired = await session.run(`
            MATCH (s:Sanction {type: 'SUSPENSION', status: 'ACTIVE'})
            WHERE s.endDate < datetime($now)
            RETURN s.id as sanctionId
        `, { now });

        for (const record of expired.records) {
            const sanctionId = record.get('sanctionId');

            // Mark sanction as expired
            await session.run(`
                MATCH (s:Sanction {id: $sanctionId})
                SET s.status = 'EXPIRED'
            `, { sanctionId });

            // Reactivate user
            await session.run(`
                MATCH (u:User)-[:HAS_SANCTION]->(s:Sanction {id: $sanctionId})
                SET u.status = 'ACTIVE',
                    u.activeSanctionId = null
            `, { sanctionId });

            console.log(`✅ Auto-lifted suspension for sanction ${sanctionId}`);
        }

        if (expired.records.length > 0) {
            console.log(`Lifted ${expired.records.length} expired suspensions`);
        }

    } catch (error) {
        console.error('Auto-lift error:', error);
    } finally {
        await session.close();
    }
}

// Run auto-lift every hour
setInterval(autoLiftExpiredSuspensions, 60 * 60 * 1000);

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
    const { firstName, lastName, username, email, password, status } = req.body;

    // Username validation: Alphanumeric only
    const usernameRegex = /^[a-zA-Z0-9]+$/;
    if (!usernameRegex.test(username)) {
        return res.status(400).json({ 
            success: false, 
            message: "USERNAME_INVALID_SYMBOLS_DETECTED" 
        });
    }

    // Password validation: 8+ chars, letters and numbers
    const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(password)) {
        return res.status(400).json({ 
            success: false, 
            message: "PASSWORD_TOO_WEAK_OR_TOO_SHORT" 
        });
    }

    const session = driver.session();

    try {
        // Check for existing email or username
        const check = await session.run(
            'MATCH (u:User) WHERE u.email = $email OR u.username = $username RETURN u.email AS email, u.username AS username', 
            { email, username }
        );
        if (check.records.length > 0) {
            const existing = check.records[0];
            if (existing.get('email') === email) {
                return res.status(400).json({ success: false, field: 'email', message: "EMAIL_EXISTS" });
            }
            if (existing.get('username') === username) {
                return res.status(400).json({ success: false, field: 'username', message: "USERNAME_TAKEN" });
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await session.run(`
            MERGE (r:Role {name: "Moderator"})
            CREATE (u:User:AuthenticatedUser:Moderator {
                id:               randomUUID(),
                firstName:        $firstName,
                lastName:         $lastName,
                username:         $username,
                email:            $email,
                password:         $hashedPassword,
                status:           $status,
                registrationDate: timestamp()
            })
            CREATE (u)-[:HAS_ROLE]->(r)
            RETURN u
        `, {
            firstName, lastName, username, email,
            hashedPassword,
            status
        });

        res.json({ success: true });

    } catch (e) {
        res.status(500).json({ success: false });
    } finally {
        await session.close();
    }
});

app.put('/api/admin/moderators/:id', async (req, res) => {
    const { id } = req.params;
    const { firstName, lastName, username, email, status, role } = req.body;

    const session = driver.session();

    try {
        // 1. Mettre à jour les propriétés de base
        await session.run(`
            MATCH (u:User {id: $id})
            SET u.firstName = $firstName,
                u.lastName = $lastName,
                u.username = $username,
                u.email = $email,
                u.status = $status
        `, { id, firstName, lastName, username, email, status });

        // 2. Si le rôle a changé, changer la relation vers le bon noeud Role existant
        if (role) {
            // Supprimer l'ancienne relation HAS_ROLE
            await session.run(`
                MATCH (u:User {id: $id})-[r:HAS_ROLE]->(:Role)
                DELETE r
            `, { id });

            // Créer la nouvelle relation avec le noeud Role existant
            await session.run(`
                MATCH (u:User {id: $id})
                MATCH (r:Role {name: $role})
                CREATE (u)-[:HAS_ROLE]->(r)
            `, { id, role });
        }

        // 3. Retourner l'utilisateur mis à jour
        const result = await session.run(`
            MATCH (u:User {id: $id})
            OPTIONAL MATCH (u)-[:HAS_ROLE]->(r:Role)
            RETURN u, r.name as role
        `, { id });

        const user = result.records[0].get('u').properties;
        const userRole = result.records[0].get('role');

        res.json({
            success: true,
            user: {
                id: user.id,
                firstName: user.firstName,
                lastName: user.lastName,
                username: user.username,
                email: user.email,
                status: user.status,
                role: userRole
            }
        });

    } catch (e) {
        console.error('Update moderator error:', e);
        res.status(500).json({ success: false, message: e.message });
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

// --- Managing roles

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

//delete role - we don't delete blindly , we have to check that the role does not have a user !
app.delete('/api/admin/roles/:id', async (req, res) => {
  const { id } = req.params;
  const session = driver.session();
  try {
    // Vérifier si des utilisateurs ont ce rôle
    const check = await session.run(`
      MATCH (u:User)-[:HAS_ROLE]->(r:Role {id: $id})
      RETURN count(u) as userCount, r.name as roleName
    `, { id });

    const userCount = check.records[0].get('userCount').toInt();
    const roleName  = check.records[0].get('roleName');

    if (userCount > 0) {
      return res.status(400).json({
        success: false,
        message: `ROLE_IN_USE`,
        details: `${roleName} is assigned to ${userCount} user(s)`
      });
    }

    await session.run(`MATCH (r:Role {id: $id}) DETACH DELETE r`, { id });
    res.json({ success: true });

  } catch(e) {
    res.status(500).json({ success: false, message: e.message });
  } finally {
    await session.close();
  }
});

app.put('/api/admin/roles/:id', async (req, res) => {
  const { id } = req.params;
  const { name, description } = req.body;
  const session = driver.session();
  try {
    const result = await session.run(`
      MATCH (r:Role {id: $id})
      SET r.name = $name,
          r.description = $description
      RETURN r
    `, { id, name, description });

    if (result.records.length === 0) {
      return res.status(404).json({ success: false, message: 'Role not found' });
    }

    res.json({ success: true, role: result.records[0].get('r').properties });
  } catch(e) {
    res.status(500).json({ success: false, message: e.message });
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

// ─────────────────────────────────────────────────────────────────────────────
// AJOUTER dans server.js — Bridge Node.js ↔ Python AI Service
// Coller AVANT app.listen(3000, ...)
// ─────────────────────────────────────────────────────────────────────────────

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

// ── Helper: call the Python AI service ────────────────────────────────────────
async function callAI(path, body) {
    const res = await fetch(`${AI_SERVICE_URL}${path}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
}

// ── POST /api/ai/analyze/comment ──────────────────────────────────────────────
// Analyse a single comment in real-time (called when a comment is posted)
app.post('/api/ai/analyze/comment', async (req, res) => {
    const { text } = req.body;
    if (!text) return res.status(400).json({ success: false, message: 'text is required' });

    try {
        const result = await callAI('/analyze/full', { text });
        res.json(result);
    } catch (e) {
        console.error('AI analyze/comment error:', e.message);
        res.status(503).json({ success: false, message: 'AI service unavailable' });
    }
});

// ── GET /api/ai/dashboard-sentiment ───────────────────────────────────────────
// Called by the admin dashboard to get platform-wide sentiment + toxicity stats
// Fetches the last N comments from Neo4j, sends them to the AI service
app.get('/api/ai/dashboard-sentiment', async (req, res) => {
    //const limit  = parseInt(req.query.limit) || 200;
    const limit = Math.floor(
      Number(req.query.limit || 200)
    );
    const session = driver.session();

    console.log(
      'dashboard limit:',
      limit,
      typeof limit
    );

    try {
        // 1. Pull recent comment texts from Neo4j
        const result = await session.run(`
            MATCH (c:Comment)
            WHERE c.content IS NOT NULL AND c.content <> ''
            RETURN c.id AS id, c.content AS content
            ORDER BY c.createdAt DESC
            LIMIT 200
        `, { limit });

        if (result.records.length === 0) {
            return res.json({
                success:  true,
                total:    0,
                sentiment: { positive: 0, neutral: 0, negative: 0, total: 0,
                             avg_scores: { positive: 0, neutral: 0, negative: 0 },
                             negativity_breakdown: { low: 0, moderate: 0, high: 0, extreme: 0 } },
                toxicity:  { total: 0, toxic_count: 0, clean_count: 0, toxic_rate: 0,
                             avg_toxic_score: 0, degree_breakdown: { low: 0, moderate: 0, high: 0, extreme: 0 },
                             severe_flag_count: 0, category_counts: {} },
                top_toxic_categories: [],
            });
        }

        // 2. Send to Python AI service
        const texts = result.records.map(r => r.get('content'));
        const aiResult = await callAI('/analyze/dashboard-summary', { texts });

        res.json(aiResult);

    } catch (e) {
        console.error('AI dashboard-sentiment error:', e.message);
        res.status(503).json({ success: false, message: 'AI service unavailable', error: e.message });
    } finally {
        await session.close();
    }
});

// ── GET /api/ai/comments-analysis ────────────────────────────────────────────
// Detailed per-comment analysis (used by moderator panel)
app.get('/api/ai/comments-analysis', async (req, res) => {
    //const limit  = parseInt(req.query.limit) || 100;
    const limit = Math.floor(
      Number(req.query.limit || 100)
    );
    const session = driver.session();

    try {
        const result = await session.run(`
            MATCH (u:User)-[:OWNS_COMMENT]->(c:Comment)
            WHERE c.content IS NOT NULL AND c.content <> ''
            RETURN c.id AS id, c.content AS content, u.username AS author
            ORDER BY c.createdAt DESC
            LIMIT $limit
        `, { limit });

        if (result.records.length === 0) {
            return res.json({ success: true, per_comment: [], aggregate: {} });
        }

        const comments = result.records.map(r => ({
            id:     r.get('id'),
            text:   r.get('content'),
            author: r.get('author'),
        }));

        // Send id + text to AI service
        const aiResult = await callAI('/analyze/batch/comments', {
            comments: comments.map(c => ({ id: c.id, text: c.text })),
        });

        // Merge author info back into per_comment
        const authorMap = Object.fromEntries(comments.map(c => [c.id, c.author]));
        const enriched = aiResult.per_comment.map(item => ({
            ...item,
            author: authorMap[item.id] ?? 'unknown',
        }));

        res.json({ ...aiResult, per_comment: enriched });

    } catch (e) {
        console.error('AI comments-analysis error:', e.message);
        res.status(503).json({ success: false, message: 'AI service unavailable' });
    } finally {
        await session.close();
    }
});

// ── POST /api/ai/analyze/post-comment ─────────────────────────────────────────
// Hook: analyse & store AI flags when a new comment is saved
// Call this from inside the POST /api/posts/comment handler after CREATE
async function analyzeAndStoreComment(commentId, content) {
    try {
        const aiResult = await callAI('/analyze/full', { text: content });
        const session  = driver.session();

        // Store AI results as properties on the Comment node
        await session.run(`
            MATCH (c:Comment {id: $commentId})
            SET c.ai_sentiment        = $sentiment,
                c.ai_sentiment_score  = $sentimentScore,
                c.ai_toxic_score      = $toxicScore,
                c.ai_is_toxic         = $isToxic,
                c.ai_degree           = $degree,
                c.ai_analyzed         = true
        `, {
            commentId,
            sentiment:      aiResult.result?.sentiment?.label      ?? 'neutral',
            sentimentScore: aiResult.result?.sentiment?.confidence ?? 0,
            toxicScore:     aiResult.result?.toxicity?.toxic_score  ?? 0,
            isToxic:        aiResult.result?.toxicity?.is_toxic     ?? false,
            degree:         aiResult.result?.toxicity?.degree       ?? 'low',
        });

        await session.close();
        console.log(`✅ AI flags stored for comment ${commentId}`);
    } catch (e) {
        // Non-blocking: AI failure should not break comment creation
        console.warn(`⚠️ AI analysis skipped for comment ${commentId}: ${e.message}`);
    }
}

// ── GET /api/ai/health ────────────────────────────────────────────────────────
app.get('/api/ai/health', async (req, res) => {
    try {
        const r = await fetch(`${AI_SERVICE_URL}/health`);
        const json = await r.json();
        res.json({ bridge: 'ok', ai_service: json });
    } catch (e) {
        res.status(503).json({ bridge: 'ok', ai_service: 'unreachable' });
    }
});



app.listen(3000, () => console.log('Backend listening on port 3000'));
