const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const neo4j = require('neo4j-driver');
require('dotenv').config();
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

// Socket mapping
const userSockets = new Map(); // userId -> socketId

io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

    socket.on('register', (userId) => {
        userSockets.set(userId, socket.id);
        console.log(`User ${userId} registered to socket ${socket.id}`);
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
        for (let [userId, sockId] of userSockets.entries()) {
            if (sockId === socket.id) {
                userSockets.delete(userId);
                break;
            }
        }
    });
});

async function sendNotification(session, type, actorId, targetId, postId = null, commentId = null, text = "") {
    if (actorId === targetId) return; // Don't notify self

    try {
        const notifId = require('crypto').randomUUID();
        const result = await session.run(`
            MATCH (target:User {id: $targetId})
            MATCH (actor:User {id: $actorId})
            OPTIONAL MATCH (actor)-[:HAS_PROFILE]->(p:Profile)
            CREATE (n:Notification {
                id: $notifId,
                type: $type,
                text: $text,
                postId: $postId,
                commentId: $commentId,
                isRead: false,
                createdAt: timestamp()
            })
            CREATE (n)-[:NOTIFIES]->(target)
            CREATE (actor)-[:INITIATED_NOTIF]->(n)
            RETURN n, actor.username as actorUsername, p.avatar as actorAvatar, actor.id as actorId
        `, { targetId, actorId, notifId, type, text, postId, commentId });
        
        if (result.records.length > 0) {
            const notif = result.records[0].get('n').properties;
            const actorUsername = result.records[0].get('actorUsername');
            const actorAvatar = result.records[0].get('actorAvatar');
            const resultActorId = result.records[0].get('actorId');
            const payload = { 
                ...notif, 
                createdAt: notif.createdAt.toNumber(), // Convert Neo4j integer to standard JS number
                actorUsername, 
                actorAvatar,
                actorId: resultActorId
            };
            
            const targetSocketId = userSockets.get(targetId);
            if (targetSocketId) {
                io.to(targetSocketId).emit('new_notification', payload);
            }
        }
    } catch (e) {
        console.error("Error creating notification:", e);
    }
}

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
const n_uri = process.env.NEO4J_URI || 'bolt://localhost:7687';
const n_user = process.env.NEO4J_USERNAME || process.env.NEO4J_USER || 'neo4j';
const n_pass = process.env.NEO4J_PASSWORD || 'truthnet123';

console.log('[Neo4j] Connecting to:', n_uri);
console.log('[Neo4j] Username:', n_user);
if (!process.env.NEO4J_PASSWORD) console.warn('[Neo4j] WARNING: Using default development password!');

const driver = neo4j.driver(
    n_uri,
    neo4j.auth.basic(n_user, n_pass)
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

    const userId = require('crypto').randomUUID();
    const profileId = require('crypto').randomUUID();

    let result;
    if (isStandardUser) {
        result = await session.run(`
          MERGE (r:Role {name: $roleName})
          CREATE (u:User:AuthenticatedUser {
            id:               $userId,
            firstName:        $firstName,
            lastName:         $lastName,
            username:         $username,
            email:            $email,
            password:         $hashedPassword,
            status:           'ACTIVE',
            registrationDate: timestamp()
          })
          CREATE (p:Profile {
            id:              $profileId,
            bio:             '',
            avatar:          null,
            privacyLevel:    'public',
            followerCount:   0,
            followingCount:  0
          })
          CREATE (u)-[:HAS_ROLE]->(r)
          CREATE (u)-[:HAS_PROFILE]->(p)
          RETURN u, r.name as role
        `, { email, hashedPassword, firstName, lastName, username, roleName: targetRole, userId, profileId });
    } else {
        const userLabel = targetRole === "Admin" ? "Administrator" : "Moderator";
        result = await session.run(`
          MERGE (r:Role {name: $roleName})
          CREATE (u:User:${userLabel} {
            id:               $userId,
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
        `, { email, hashedPassword, firstName, lastName, username, roleName: targetRole, userId });
    }

    const user = result.records[0].get('u').properties;
    res.json({
      success: true,
      user: { ...user, role: result.records[0].get('role') }
    });

  } catch (e) {
      console.log("Error in /api/users/follow:", e);
      res.status(500).json({ success: false, message: e.message });
  } finally {
      await session.close();
  }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User) WHERE u.email = $email OR u.username = $email
             OPTIONAL MATCH (u)-[:HAS_ROLE]->(r:Role)
             OPTIONAL MATCH (u)-[:HAS_SANCTION]->(s:Sanction {status: 'ACTIVE'})
             RETURN u, r.name as role, collect(s) as sanctions`, 
            { email }
        );

        if (result.records.length > 0) {
            const firstRecord = result.records[0];
            const user = firstRecord.get('u').properties;
            const role = firstRecord.get('role');
            const sanctions = firstRecord.get('sanctions').map(s => s.properties);

            if (await bcrypt.compare(password, user.password)) {
                // Check status
                const status = (user.status || 'ACTIVE').toUpperCase();
                
                if (status === 'INACTIVE') {
                    return res.status(403).json({ 
                        success: false, 
                        message: "ACCOUNT_DEACTIVATED",
                        detail: "Your account has been deactivated by an administrator."
                    });
                }

                if (status === 'BANNED') {
                    return res.status(403).json({ 
                        success: false, 
                        message: "ACCOUNT_BANNED",
                        detail: "Your account has been permanently banned."
                    });
                }

                if (status === 'SUSPENDED') {
                    const now = new Date();
                    // Check if ANY active sanction is still in the future
                    const activeSanction = sanctions.find(s => s.endDate && new Date(s.endDate) > now);
                    
                    if (activeSanction) {
                        return res.status(403).json({ 
                            success: false, 
                            message: "ACCOUNT_SUSPENDED",
                            detail: `Your account is suspended until ${activeSanction.endDate}.`,
                            until: activeSanction.endDate
                        });
                    } else {
                        // All sanctions expired, reactivate user
                        await session.run('MATCH (u:User {id: $id}) SET u.status = "ACTIVE"', { id: user.id });
                        user.status = 'ACTIVE';
                    }
                }

                res.json({ success: true, user: { ...user, role } });
            } else {
                res.status(401).json({ success: false, message: "INVALID_CREDENTIALS" });
            }
        } else {
            res.status(401).json({ success: false, message: "USER_NOT_FOUND" });
        }
    } catch (e) {
        console.error("DB Error:", e.message);
        res.status(500).json({ success: false, message: e.message });
    } finally {
        await session.close();
    }
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

// --- SETTINGS (GLOBAL PLATFORM CONFIG) ---

app.get('/api/admin/settings', async (req, res) => {
    const session = driver.session();
    try {
        const result = await session.run(`
            MERGE (s:Settings {id: 'global'})
            ON CREATE SET s.truthThreshold = 0.40
            RETURN s.truthThreshold AS truthThreshold
        `);
        res.json({ success: true, truthThreshold: result.records[0].get('truthThreshold') });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    } finally {
        await session.close();
    }
});

app.put('/api/admin/settings', async (req, res) => {
    const { truthThreshold } = req.body;
    const session = driver.session();
    try {
        await session.run(`
            MERGE (s:Settings {id: 'global'})
            SET s.truthThreshold = $truthThreshold
        `, { truthThreshold });
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    } finally {
        await session.close();
    }
});

app.get('/api/feed', async (req, res) => {
    const userId = req.query.userId;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (s:Settings {id: 'global'})
             WITH coalesce(s.truthThreshold, 0.40) AS threshold
             MATCH (u:User)-[:OWNS_POST]->(p:Post)
             WHERE p.visibility = 'public' AND (p.isDeleted IS NULL OR p.isDeleted = false)
               AND (p.truthScore IS NULL OR toFloat(p.truthScore) >= threshold)
             RETURN u.username as author, u.id as authorId, p as post,
                    COUNT { (p)<-[:HAS_REACTION]-() } as likeCount,
                    COUNT { (p)<-[:HAS_COMMENT]-() } as commentCount,
                    COUNT { (p)<-[:SHARED]-() } as shareCount,
                    EXISTS { (p)<-[:SAVED]-(:User {id: $userId}) } as isSaved,
                    EXISTS { (p)<-[:HAS_REACTION]-(r:Reaction {targetType: 'Post'})<-[:OWNS_REACTION]-(:User {id: $userId}) } as isLiked
             ORDER BY p.createdAt DESC`,
            { userId: userId || "" }
        );
        res.json(result.records.map(r => {
            const postProps = r.get('post').properties;
            return {
                author: r.get('author'),
                authorId: r.get('authorId'),
                ...postProps,
                likeCount: r.get('likeCount').toInt(),
                commentCount: r.get('commentCount').toInt(),
                shareCount: r.get('shareCount').toInt(),
                isSaved: r.get('isSaved'),
                isLiked: r.get('isLiked'),
                
                // Explicitly mapping fact-check results
                truthScore: postProps.truthScore,
                truthVerdict: postProps.truthVerdict,
                truthExplanation: postProps.truthExplanation,
                truthSources: postProps.truthSources
            };
        }));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.get('/api/users/search', async (req, res) => {
    const { query, excludeId } = req.query;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)
             WHERE toLower(u.username) CONTAINS toLower($query)
               AND u.id <> $excludeId
             OPTIONAL MATCH (me:User {id: $excludeId})-[r1:FOLLOWS]->(u)
             OPTIONAL MATCH (u)-[r2:FOLLOWS]->(me)
             WITH u,
                  CASE WHEN r1 IS NOT NULL AND r2 IS NOT NULL THEN 3
                       WHEN r1 IS NOT NULL THEN 2
                       WHEN r2 IS NOT NULL THEN 1
                       ELSE 0 END AS priority
             ORDER BY priority DESC, u.username ASC
             RETURN u.username as name, u.id as id LIMIT 10`,
            { query: query || "", excludeId: excludeId || "" }
        );
        res.json(result.records.map(r => ({ name: r.get('name'), id: r.get('id') })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.get('/api/posts/search', async (req, res) => {
    const { query, excludeId } = req.query;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:OWNS_POST]->(p:Post)
             WHERE toLower(coalesce(p.content, '')) CONTAINS toLower($query) 
               AND u.id <> $excludeId
               AND (p.isDeleted IS NULL OR p.isDeleted = false)
               AND p.visibility = 'public'
             RETURN u.username as author, u.id as authorId, p as post LIMIT 10`,
            { query: query || "", excludeId: excludeId || "" }
        );
        res.json(result.records.map(r => ({ author: r.get('author'), authorId: r.get('authorId'), ...r.get('post').properties })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.post('/api/users/follow', async (req, res) => {
    const { userId, targetId } = req.body;
    const session = driver.session();
    try {
        const check = await session.run('MATCH (a:User {id: $userId})-[r:FOLLOWS]->(b:User {id: $targetId}) RETURN r', { userId, targetId });
        if (check.records.length > 0) {
            // Unfollow
            await session.run('MATCH (a:User {id: $userId})-[r:FOLLOWS]->(b:User {id: $targetId}) DELETE r', { userId, targetId });
            await session.run('MATCH (p1:Profile)<-[:HAS_PROFILE]-(:User {id: $userId}) SET p1.followingCount = p1.followingCount - 1', { userId });
            await session.run('MATCH (p2:Profile)<-[:HAS_PROFILE]-(:User {id: $targetId}) SET p2.followerCount = p2.followerCount - 1', { targetId });
            res.json({ success: true, action: 'unfollowed' });
        } else {
            // Follow
            await session.run('MATCH (a:User {id: $userId}), (b:User {id: $targetId}) CREATE (a)-[:FOLLOWS]->(b)', { userId, targetId });
            await session.run('MATCH (p1:Profile)<-[:HAS_PROFILE]-(:User {id: $userId}) SET p1.followingCount = p1.followingCount + 1', { userId });
            await session.run('MATCH (p2:Profile)<-[:HAS_PROFILE]-(:User {id: $targetId}) SET p2.followerCount = p2.followerCount + 1', { targetId });
            
            // Send notification
            await sendNotification(session, 'follow', userId, targetId, null, null, "started following you");
            
            res.json({ success: true, action: 'followed' });
        }
    } catch (e) {
        console.log("Error in /api/users/follow:", e);
        res.status(500).json({ success: false, message: e.message });
    } finally {
        await session.close();
    }
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
            const createResult = await session.run(`
                MATCH (u:User {id: $userId})
                MATCH (p:Post {id: $postId})<-[:OWNS_POST]-(owner:User)
                CREATE (r:Reaction {
                    id: randomUUID(),
                    type: 'LIKE',
                    targetType: 'Post',
                    createdAt: timestamp()
                })
                CREATE (u)-[:OWNS_REACTION]->(r)
                CREATE (r)-[:TARGETS]->(p)
                CREATE (r)-[:HAS_REACTION]->(p)
                RETURN owner.id as ownerId
            `, { userId, postId });
            
            if (createResult.records.length > 0) {
                const ownerId = createResult.records[0].get('ownerId');
                await sendNotification(session, 'like_post', userId, ownerId, postId, null, "liked your post");
            }
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

// --- MESSAGES ---

app.post('/api/messages', async (req, res) => {
    const { senderId, receiverId, content } = req.body;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (sender:User {id: $senderId}), (receiver:User {id: $receiverId})
             CREATE (m:Message {id: randomUUID(), content: $content, createdAt: timestamp()})
             CREATE (sender)-[:SENT]->(m)-[:TO]->(receiver)
             RETURN m`,
            { senderId, receiverId, content }
        );
        res.json({ success: true, message: result.records[0].get('m').properties });
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.get('/api/messages/history/:userId/:otherId', async (req, res) => {
    const { userId, otherId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (sender:User)-[:SENT]->(m:Message)-[:TO]->(receiver:User)
             WHERE (sender.id = $userId AND receiver.id = $otherId)
                OR (sender.id = $otherId AND receiver.id = $userId)
             RETURN m.id as id, m.content as content, m.createdAt as createdAt, sender.id as senderId
             ORDER BY m.createdAt ASC`,
            { userId, otherId }
        );
        res.json(result.records.map(r => ({
            id: r.get('id'), content: r.get('content'), createdAt: r.get('createdAt').toNumber(), senderId: r.get('senderId')
        })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.get('/api/messages/conversations/:userId', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})
             MATCH (u)-[:SENT]->(m:Message)-[:TO]->(other:User)
             WITH other, m ORDER BY m.createdAt DESC
             WITH other, collect(m)[0] as lastMsg
             RETURN other.id as id, other.username as username, lastMsg.content as lastMessage, lastMsg.createdAt as lastMessageAt
             UNION
             MATCH (u:User {id: $userId})
             MATCH (other:User)-[:SENT]->(m:Message)-[:TO]->(u)
             WITH other, m ORDER BY m.createdAt DESC
             WITH other, collect(m)[0] as lastMsg
             RETURN other.id as id, other.username as username, lastMsg.content as lastMessage, lastMsg.createdAt as lastMessageAt`,
            { userId }
        );
        const convos = {};
        result.records.forEach(r => {
            const id = r.get('id');
            const time = r.get('lastMessageAt').toNumber();
            if (!convos[id] || convos[id].lastMessageAt < time) {
                convos[id] = { id, username: r.get('username'), lastMessage: r.get('lastMessage'), lastMessageAt: time };
            }
        });
        res.json(Object.values(convos).sort((a,b) => b.lastMessageAt - a.lastMessageAt));
    } catch (e) { res.status(500).json([]); }
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

            OPTIONAL MATCH ()-[r:REPORTED]->()
            WITH users, posts, comments, count(r) as reports,
                 sum(CASE WHEN r.status = 'pending' THEN 1 ELSE 0 END) as pendingReports,
                 sum(CASE WHEN r.status = 'resolved' THEN 1 ELSE 0 END) as resolvedReports

            RETURN users, posts, comments, reports, pendingReports, resolvedReports
        `);

        const record = result.records[0];

        res.json({
            users: record.get('users').toInt(),
            posts: record.get('posts').toInt(),
            comments: record.get('comments').toInt(),
            reports: record.get('reports').toInt(),
            pendingReports: record.get('pendingReports').toInt(),
            resolvedReports: record.get('resolvedReports').toInt()
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
    const { currentUserId } = req.query;
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
             RETURN u, profile,
                    count(DISTINCT p) as postCount,
                    profile.followerCount as followerCount,
                    profile.followingCount as followingCount,
                    EXISTS((:User {id: $currentUserId})-[:FOLLOWS]->(u)) as isFollowing`,
            { userId, currentUserId: currentUserId || "" }
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
                isFollowing: profileResult.records[0].get('isFollowing'),
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
        res.json(result.records.map(r => {
            const postProps = r.get('post').properties;
            return {
                author: r.get('author'),
                ...postProps,
                // Explicit mapping
                truthScore: postProps.truthScore,
                truthVerdict: postProps.truthVerdict,
                truthExplanation: postProps.truthExplanation,
                truthSources: postProps.truthSources
            };
        }));
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
        res.json(result.records.map(r => {
            const postProps = r.get('post').properties;
            return {
                author: r.get('author'),
                ...postProps,
                // Explicit mapping
                truthScore: postProps.truthScore,
                truthVerdict: postProps.truthVerdict,
                truthExplanation: postProps.truthExplanation,
                truthSources: postProps.truthSources
            };
        }));
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
    
    // Maintain mediaUrl field for backward compatibility (first image)
    const primaryMediaUrl = mediaUrls.length > 0 ? mediaUrls[0] : null;

    // Protocol Check: Strictly MP4 for videos
    if (isVideo) {
      const invalidFiles = req.files ? req.files.filter(f => !f.originalname.toLowerCase().endsWith('.mp4')) : [];
      if (invalidFiles.length > 0) {
        return res.status(400).json({ success: false, message: "PROTOCOL_VIOLATION: ONLY_MP4_ALLOWED" });
      }
    }

    // Toxicity Check
    if (content && content.trim().length > 0) {
        try {
            const aiRes = await callAI('/analyze/toxicity', { text: content });
            if (aiRes.success && aiRes.result && aiRes.result.degree === 'extreme') {
                return res.status(400).json({ 
                    success: false, 
                    message: "CONTENT_TOO_TOXIC",
                    detail: "Your content has been flagged as extremely toxic and cannot be published."
                });
            }
        } catch (aiErr) {
            console.warn("AI Toxicity check failed (skipping):", aiErr.message);
        }
    }

    const session = driver.session();

    // Fetch global threshold
    let globalThreshold = 0.40;
    try {
        const settingsRes = await session.run(`
            MERGE (s:Settings {id: 'global'})
            ON CREATE SET s.truthThreshold = 0.40
            RETURN s.truthThreshold AS truthThreshold
        `);
        globalThreshold = settingsRes.records[0].get('truthThreshold');
    } catch (e) {
        console.warn("Could not fetch global settings, defaulting to 0.40");
    }

    // --- NEW: Mandatory Fact-Check before publishing ---
    let factCheckData = null;
    try {
        console.log(`[POST] Running mandatory fact-check for user ${userId}...`);
        const factCheckRes = await callAI('/analyze/verify', { 
            text: content || "[IMAGE_ONLY_POST]", 
            image_url: primaryMediaUrl, 
            is_video: isVideo 
        });

        if (factCheckRes.success) {
            factCheckData = factCheckRes;
            
            // Block based on dynamic global threshold
            const isNonsense = factCheckRes.type === 'nonsense';
            const score = factCheckRes.truth_score || 0;
            
            if (isNonsense || (factCheckRes.type === 'claim' && score < globalThreshold)) {
                console.warn(`[POST] Publication blocked: score ${score} is below threshold ${globalThreshold}`);
                await session.close();
                return res.status(400).json({
                    success: false,
                    message: isNonsense ? "CONTENT_NONSENSE" : "CONTENT_UNVERIFIED",
                    detail: factCheckRes.explanation,
                    verdict: factCheckRes.verdict,
                    truth_score: factCheckRes.truth_score
                });
            }
        }
    } catch (fcErr) {
        console.warn("AI Fact-check failed (skipping to allow publication):", fcErr.message);
    }

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
                createdAt: timestamp(),
                
                // Store fact-check results
                truthScore: $truthScore,
                truthVerdict: $truthVerdict,
                truthExplanation: $truthExplanation,
                truthSources: $truthSources
             })
             CREATE (u)-[:OWNS_POST]->(p)
             RETURN p`,
            { 
                userId, 
                content, 
                primaryMediaUrl, 
                mediaUrls, 
                location: location || null, 
                isVideo, 
                visibility,
                truthScore: factCheckData ? factCheckData.truth_score : null,
                truthVerdict: factCheckData ? factCheckData.verdict : null,
                truthExplanation: factCheckData ? factCheckData.explanation : null,
                truthSources: factCheckData ? (factCheckData.sources || []) : []
            }
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


app.get('/api/posts/:postId', async (req, res) => {
    const { postId } = req.params;
    const userId = req.query.userId;
    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User)-[:OWNS_POST]->(p:Post {id: $postId})
             WHERE (p.isDeleted IS NULL OR p.isDeleted = false)
             RETURN u.username as author, u.id as authorId, p as post,
                    COUNT { (p)<-[:HAS_REACTION]-() } as likeCount,
                    COUNT { (p)<-[:HAS_COMMENT]-() } as commentCount,
                    COUNT { (p)<-[:SHARED]-() } as shareCount,
                    EXISTS { (p)<-[:SAVED]-(:User {id: $userId}) } as isSaved,
                    EXISTS { (p)<-[:HAS_REACTION]-(r:Reaction {targetType: 'Post'})<-[:OWNS_REACTION]-(:User {id: $userId}) } as isLiked`,
            { postId, userId: userId || "" }
        );
        if (result.records.length > 0) {
            const r = result.records[0];
            const postProps = r.get('post').properties;
            res.json({
                author: r.get('author'),
                authorId: r.get('authorId'),
                ...postProps,
                likeCount: r.get('likeCount').toInt(),
                commentCount: r.get('commentCount').toInt(),
                shareCount: r.get('shareCount').toInt(),
                isSaved: r.get('isSaved'),
                isLiked: r.get('isLiked'),
                
                // Stored fact-check
                truthScore: postProps.truthScore,
                truthVerdict: postProps.truthVerdict,
                truthExplanation: postProps.truthExplanation,
                truthSources: postProps.truthSources
            });
        } else {
            res.status(404).json({ message: "POST_NOT_FOUND" });
        }
    } catch (e) { res.status(500).json({ message: e.message }); }
    finally { await session.close(); }
});

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
        res.json(result.records.map(r => {
            const props = r.get('comment').properties;
            return {
                author: r.get('author'),
                authorId: r.get('authorId'),
                ...props,
                likeCount: r.get('likeCount').toInt(),
                replyCount: r.get('replyCount').toInt(),
                
                // Stored fact-check
                truthScore: props.truthScore,
                truthVerdict: props.truthVerdict,
                truthExplanation: props.truthExplanation,
                truthSources: props.truthSources
            };
        }));
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
            const createResult = await session.run(`
                MATCH (u:User {id: $userId})
                MATCH (c:Comment {id: $commentId})<-[:OWNS_COMMENT]-(owner:User)
                MATCH (c)-[:TARGETS*1..]->(p:Post)
                CREATE (r:Reaction {
                    id: randomUUID(),
                    type: 'LIKE',
                    targetType: 'Comment',
                    createdAt: timestamp()
                })
                CREATE (u)-[:OWNS_REACTION]->(r)
                CREATE (r)-[:TARGETS]->(c)
                CREATE (r)-[:HAS_REACTION]->(c)
                RETURN owner.id as ownerId, p.id as postId
            `, { userId, commentId });
            
            if (createResult.records.length > 0) {
                const ownerId = createResult.records[0].get('ownerId');
                const postId = createResult.records[0].get('postId');
                await sendNotification(session, 'like_comment', userId, ownerId, postId, commentId, "liked your comment");
            }
            res.json({ success: true, action: 'liked' });
        }
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/posts/comment', async (req, res) => {
    const { userId, postId, content } = req.body;

    // Toxicity Check
    if (content && content.trim().length > 0) {
        try {
            const aiRes = await callAI('/analyze/toxicity', { text: content });
            if (aiRes.success && aiRes.result && aiRes.result.degree === 'extreme') {
                return res.status(400).json({ 
                    success: false, 
                    message: "CONTENT_TOO_TOXIC",
                    detail: "Your comment has been flagged as extremely toxic and cannot be published."
                });
            }
        } catch (aiErr) {
            console.warn("AI Toxicity check failed (skipping):", aiErr.message);
        }
    }

    // --- NEW: Mandatory Fact-Check before publishing ---
    let factCheckData = null;
    try {
        console.log(`[COMMENT] Running mandatory fact-check for user ${userId}...`);
        const factCheckRes = await callAI('/analyze/verify', { 
            text: content
        });

        if (factCheckRes.success) {
            factCheckData = factCheckRes;
            if (factCheckRes.truth_score < 0.3) {
                return res.status(400).json({
                    success: false,
                    message: "CONTENT_UNVERIFIED",
                    detail: factCheckRes.explanation,
                    verdict: factCheckRes.verdict,
                    truth_score: factCheckRes.truth_score
                });
            }
        }
    } catch (fcErr) {
        console.warn("AI Fact-check failed (skipping):", fcErr.message);
    }

    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId}), (p:Post {id: $postId})<-[:OWNS_POST]-(owner:User)
             CREATE (c:Comment {
                id: randomUUID(), 
                content: $content, 
                createdAt: timestamp(),
                // Store fact-check results
                truthScore: $truthScore,
                truthVerdict: $truthVerdict,
                truthExplanation: $truthExplanation,
                truthSources: $truthSources
             })
             CREATE (u)-[:OWNS_COMMENT]->(c)
             CREATE (c)-[:TARGETS]->(p)
             CREATE (p)-[:HAS_COMMENT]->(c)
             RETURN c, owner.id as ownerId`,
            { 
                userId, postId, content,
                truthScore: factCheckData ? factCheckData.truth_score : null,
                truthVerdict: factCheckData ? factCheckData.verdict : null,
                truthExplanation: factCheckData ? factCheckData.explanation : null,
                truthSources: factCheckData ? (factCheckData.sources || []) : []
            }
        );
        const comment = result.records[0].get('c').properties;
        const ownerId = result.records[0].get('ownerId');
        
        await sendNotification(session, 'comment', userId, ownerId, postId, comment.id, "commented on your post");
        analyzeAndStoreComment(comment.id, content); // fire and forget
        
        res.json({ success: true, comment });
    } catch (e) { res.status(500).json({ success: false, message: e.message }); }
    finally { await session.close(); }
});

app.post('/api/comments/:commentId/reply', async (req, res) => {
    const { userId, content } = req.body;
    const { commentId } = req.params;

    // Toxicity Check
    if (content && content.trim().length > 0) {
        try {
            const aiRes = await callAI('/analyze/toxicity', { text: content });
            if (aiRes.success && aiRes.result && aiRes.result.degree === 'extreme') {
                return res.status(400).json({ 
                    success: false, 
                    message: "CONTENT_TOO_TOXIC",
                    detail: "Your reply has been flagged as extremely toxic and cannot be published."
                });
            }
        } catch (aiErr) {
            console.warn("AI Toxicity check failed (skipping):", aiErr.message);
        }
    }

    // --- NEW: Mandatory Fact-Check before publishing ---
    let factCheckData = null;
    try {
        const factCheckRes = await callAI('/analyze/verify', { text: content });
        if (factCheckRes.success) {
            factCheckData = factCheckRes;
            if (factCheckRes.truth_score < 0.3) {
                return res.status(400).json({
                    success: false,
                    message: "CONTENT_UNVERIFIED",
                    detail: factCheckRes.explanation
                });
            }
        }
    } catch (fcErr) {}

    const session = driver.session();
    try {
        const result = await session.run(
            `MATCH (u:User {id: $userId})
             MATCH (target:Comment {id: $commentId})<-[:OWNS_COMMENT]-(owner:User)
             MATCH (target)-[:TARGETS*1..]->(p:Post)
             CREATE (reply:Comment {
                id: randomUUID(), 
                content: $content, 
                createdAt: timestamp(),
                // Store fact-check results
                truthScore: $truthScore,
                truthVerdict: $truthVerdict,
                truthExplanation: $truthExplanation,
                truthSources: $truthSources
             })
             CREATE (u)-[:OWNS_COMMENT]->(reply)
             CREATE (reply)-[:REPLIED_TO]->(target)
             CREATE (reply)-[:TARGETS]->(p)
             RETURN reply, owner.id as ownerId, p.id as postId`,
            { 
                userId, commentId, content,
                truthScore: factCheckData ? factCheckData.truth_score : null,
                truthVerdict: factCheckData ? factCheckData.verdict : null,
                truthExplanation: factCheckData ? factCheckData.explanation : null,
                truthSources: factCheckData ? (factCheckData.sources || []) : []
            }
        );
        const reply = result.records[0].get('reply').properties;
        const ownerId = result.records[0].get('ownerId');
        const postId = result.records[0].get('postId');
        
        await sendNotification(session, 'reply', userId, ownerId, postId, reply.id, "replied to your comment");
        analyzeAndStoreComment(reply.id, content); // fire and forget
        
        res.json({ success: true, reply });
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

// --- NOTIFICATIONS ---

app.get('/api/notifications/:userId', async (req, res) => {
    const { userId } = req.params;
    const session = driver.session();
    try {
        const result = await session.run(`
            MATCH (n:Notification)-[:NOTIFIES]->(u:User {id: $userId})
            MATCH (actor:User)-[:INITIATED_NOTIF]->(n)
            OPTIONAL MATCH (actor)-[:HAS_PROFILE]->(p:Profile)
            RETURN n.id as id, n.type as type, n.text as text, n.postId as postId, n.commentId as commentId, n.isRead as isRead, n.createdAt as createdAt, actor.username as actorUsername, p.avatar as actorAvatar, actor.id as actorId
            ORDER BY n.createdAt DESC LIMIT 50
        `, { userId });
        
        res.json(result.records.map(r => ({
            id: r.get('id'),
            type: r.get('type'),
            text: r.get('text'),
            postId: r.get('postId'),
            commentId: r.get('commentId'),
            isRead: r.get('isRead'),
            createdAt: r.get('createdAt').toNumber(),
            actorUsername: r.get('actorUsername'),
            actorAvatar: r.get('actorAvatar'),
            actorId: r.get('actorId')
        })));
    } catch (e) { res.status(500).json([]); }
    finally { await session.close(); }
});

app.put('/api/notifications/:notifId/read', async (req, res) => {
    const { notifId } = req.params;
    const session = driver.session();
    try {
        await session.run(`MATCH (n:Notification {id: $notifId}) SET n.isRead = true`, { notifId });
        res.json({ success: true });
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
            WITH u, r, p, s ORDER BY s.startDate DESC
            WITH u, r, p, collect(s)[0] as latestSanction
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
                latestSanction.id   AS sanctionId,
                latestSanction.type AS sanctionType,
                latestSanction.reason AS sanctionReason,
                latestSanction.endDate AS sanctionEndDate
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
  const { reason, durationDays, endDate: customEndDate, adminId } = req.body;
  const session = driver.session();

  const sanctionId = require('crypto').randomUUID();
  const startDate  = new Date().toISOString();
  
  let endDate;
  if (customEndDate) {
    endDate = new Date(customEndDate).toISOString();
  } else {
    endDate = new Date(
      Date.now() + (durationDays || 1) * 24 * 60 * 60 * 1000
    ).toISOString();
  }

  try {
    await session.run(`
      MATCH (u:User {id: $userId})
      CREATE (s:Sanction {
        id:            $sanctionId,
        type:          'SUSPENSION',
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
    const { adminId } = req.body;

    const session = driver.session();

    try {
        // 1. Reactivate user
        await session.run(
            `MATCH (u:User {id: $userId})
             SET u.status = 'ACTIVE',
                 u.activeSanctionId = null
             RETURN u`,
            { userId }
        );

        // 2. Revoke any active sanctions
        await session.run(
            `MATCH (u:User {id: $userId})-[:HAS_SANCTION]->(s:Sanction {status: 'ACTIVE'})
             SET s.status = 'REVOKED',
                 s.revokedAt = timestamp(),
                 s.revokedBy = $adminId
             RETURN s`,
            { userId, adminId: adminId || 'SYSTEM' }
        );

        res.json({
            success: true,
            message: "User activated successfully and sanctions revoked"
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
            WHERE s.endDate < $now
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

        const moderators = result.records.map(r => {
            const props = r.get('u').properties;
            return {
                ...props,
                name: `${props.firstName || ''} ${props.lastName || ''}`.trim(),
                role: r.get('role')
            };
        });

        res.json(moderators);

    } catch (e) {
        res.status(500).json([]);
    } finally {
        await session.close();
    }
});

// add moderator
app.post('/api/admin/moderators', async (req, res) => {
    let { firstName, lastName, name, username, email, password, status } = req.body;

    // Handle 'name' from frontend if firstName/lastName are missing
    if (name && !firstName) {
        const parts = name.trim().split(/\s+/);
        firstName = parts[0];
        lastName = parts.slice(1).join(' ');
    }

    firstName = firstName || 'Moderator';
    lastName = lastName || '';
    status = status || 'ACTIVE';

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

        const id = require('crypto').randomUUID();
        await session.run(`
            MERGE (r:Role {name: "Moderator"})
            CREATE (u:User:AuthenticatedUser:Moderator {
                id:               $id,
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
            id,
            firstName,
            lastName,
            username,
            email,
            hashedPassword,
            status
        });

        res.json({ success: true });

    } catch (e) {
        console.error("Add moderator error:", e);
        res.status(500).json({ success: false, message: e.message });
    } finally {
        await session.close();
    }
});

app.put('/api/admin/moderators/:id', async (req, res) => {
    const { id } = req.params;
    let { firstName, lastName, name, username, email, status, role } = req.body;

    // Handle 'name' from frontend if firstName/lastName are missing
    if (name && !firstName) {
        const parts = name.trim().split(/\s+/);
        firstName = parts[0];
        lastName = parts.slice(1).join(' ');
    }

    firstName = firstName || 'Moderator';
    lastName = lastName || '';
    status = status || 'ACTIVE';

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
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
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
      MATCH (r:Role {id: $id})
      OPTIONAL MATCH (u:User)-[:HAS_ROLE]->(r)
      RETURN count(u) as userCount, r.name as roleName
    `, { id });

    if (check.records.length === 0) {
      return res.status(404).json({ success: false, message: 'Role not found' });
    }

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

    const roles = result.records.map(r => {
      const props = r.get('r').properties;
      return {
        id: props.id, // property id (UUID)
        ...props
      };
    });

    res.json(roles);
  } finally {
    await session.close();
  }
});

// ==========================================
// REPORTING SYSTEM (POSTS / COMMENTS)
// ==========================================
const { v4: uuidv4 } = require('uuid');

app.post('/api/reports', async (req, res) => {
  const { reporterId, targetId, targetType, reason } = req.body;
  const session = driver.session();
  try {
    const timestamp = Date.now();
    const reportId = uuidv4();
    let query = '';

    if (targetType === 'Post') {
      query = `
        MATCH (u:User {id: $reporterId})
        MATCH (p:Post {id: $targetId})
        CREATE (u)-[r:REPORTED { id: $reportId, reason: $reason, timestamp: $timestamp, status: 'pending' }]->(p)
        RETURN r
      `;
    } else if (targetType === 'Comment') {
      query = `
        MATCH (u:User {id: $reporterId})
        MATCH (c:Comment {id: $targetId})
        CREATE (u)-[r:REPORTED { id: $reportId, reason: $reason, timestamp: $timestamp, status: 'pending' }]->(c)
        RETURN r
      `;
    } else {
      return res.status(400).json({ success: false, message: 'Invalid targetType' });
    }

    const result = await session.run(query, { reporterId, targetId, reason, timestamp, reportId });
    if (result.records.length === 0) {
        return res.status(404).json({ success: false, message: 'Target or Reporter not found' });
    }
    res.json({ success: true, message: 'Report submitted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  } finally {
    await session.close();
  }
});

app.get('/api/admin/reports', async (req, res) => {
  const session = driver.session();
  try {
    const query = `
      MATCH (u:User)-[r:REPORTED]->(target)
      WHERE r.status = 'pending'
      OPTIONAL MATCH (target)<-[:OWNS_POST|OWNS_COMMENT]-(author:User)
      RETURN
        r.id as id,
        u.id as reporterId,
        u.username as reporterName,
        target.id as targetId,
        labels(target)[0] as targetType,
        target.content as targetContent,
        author.id as authorId,
        author.username as authorName,
        r.reason as reason,
        r.timestamp as timestamp
      ORDER BY r.timestamp DESC
    `;
    const result = await session.run(query);
    const reports = result.records.map(record => ({
      id: record.get('id'),
      reporterId: record.get('reporterId'),
      reporterName: record.get('reporterName'),
      targetId: record.get('targetId'),
      targetType: record.get('targetType'),
      targetContent: record.get('targetContent') || "",
      authorId: record.get('authorId') || null,
      authorName: record.get('authorName') || 'Unknown',
      reason: record.get('reason') || 'No reason',
      timestamp: record.get('timestamp') ? (typeof record.get('timestamp').toNumber === 'function' ? record.get('timestamp').toNumber() : record.get('timestamp')) : Date.now()
    }));
    res.json(reports);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  } finally {
    await session.close();
  }
});

app.put('/api/admin/reports/:reportId/resolve', async (req, res) => {
  const { reportId } = req.params;
  const { action, adminId, customReason } = req.body; // 'dismiss' or 'delete'
  const session = driver.session();
  try {
    if (action === 'delete') {
      const findQuery = `
        MATCH ()-[r:REPORTED {id: $reportId}]->(target)
        OPTIONAL MATCH (target)<-[:OWNS_POST|OWNS_COMMENT]-(owner:User)
        RETURN target.id as targetId, labels(target)[0] as type, owner.id as ownerId
      `;
      const findRes = await session.run(findQuery, { reportId });
      
      if (findRes.records.length > 0) {
          const targetId = findRes.records[0].get('targetId');
          const ownerId = findRes.records[0].get('ownerId');
          const type = findRes.records[0].get('type');
          
          if (ownerId && adminId) {
             const contentType = type === 'Post' ? "your post" : "your comment";
             const defaultMessage = `The moderator has deleted ${contentType} because it does not respect the application's rules.`;
             const notifText = customReason ? `${defaultMessage} Reason: ${customReason}` : defaultMessage;

             await sendNotification(
                 session, 
                 'system_alert', 
                 adminId, 
                 ownerId, 
                 type === 'Post' ? targetId : null, 
                 type === 'Comment' ? targetId : null, 
                 notifText
             );
          }
          
          await session.run(`MATCH (target) WHERE target.id = $targetId DETACH DELETE target`, { targetId });
      }
      res.json({ success: true, message: 'Report resolved and target deleted' });
    } else {
      const dismissQuery = `
        MATCH ()-[r:REPORTED {id: $reportId}]->()
        SET r.status = 'resolved'
      `;
      await session.run(dismissQuery, { reportId });
      res.json({ success: true, message: 'Report dismissed' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  } finally {
    await session.close();
  }
});

app.post('/api/admin/reports/:reportId/analyze', async (req, res) => {
    const { reportId } = req.params;
    console.log(`[ADMIN] Analyzing report: ${reportId}`);
    const session = driver.session();
    try {
        const findRes = await session.run(
            `MATCH ()-[r:REPORTED {id: $reportId}]->(target)
             RETURN target.id as id, target.content as content, labels(target)[0] as type`,
            { reportId }
        );

        if (findRes.records.length === 0) {
            console.warn(`[ADMIN] Report not found: ${reportId}`);
            return res.status(404).json({ success: false, message: 'Target not found' });
        }

        const content = findRes.records[0].get('content');
        if (!content || content.trim() === "") {
            console.warn(`[ADMIN] No content for target in report: ${reportId}`);
            return res.status(400).json({ success: false, message: 'No text content to analyze' });
        }

        console.log(`[ADMIN] Calling AI for content: "${content.substring(0, 50)}..."`);
        const aiResult = await callAI('/analyze/full', { text: content });
        res.json({ success: true, analysis: aiResult });
    } catch(e) {
        console.error(`[ADMIN] Analysis error for report ${reportId}:`, e.message);
        res.status(500).json({ success: false, message: e.message });
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
            RETURN date(datetime({epochMillis: p.createdAt})) as day,
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

// Truthness score summary for the admin dashboard.
app.get('/api/admin/truthness-summary', async (req, res) => {
    const session = driver.session();

    const asNumber = (value) => {
        if (value && typeof value.toNumber === 'function') return value.toNumber();
        return Number(value || 0);
    };

    try {
        const summaryResult = await session.run(`
            OPTIONAL MATCH (s:Settings {id: 'global'})
            WITH coalesce(s.truthThreshold, 0.40) AS threshold
            MATCH (p:Post)
            WHERE p.truthScore IS NOT NULL
              AND (p.isDeleted IS NULL OR p.isDeleted = false)
            WITH p, toFloat(p.truthScore) AS score, threshold
            RETURN count(p) AS total,
                   avg(score) AS averageScore,
                   sum(CASE WHEN score >= 0.75 THEN 1 ELSE 0 END) AS reliable,
                   sum(CASE WHEN score >= threshold AND score < 0.75 THEN 1 ELSE 0 END) AS uncertain,
                   sum(CASE WHEN score < threshold THEN 1 ELSE 0 END) AS lowTrust
        `);

        const trendResult = await session.run(`
            MATCH (p:Post)
            WHERE p.truthScore IS NOT NULL
              AND p.createdAt IS NOT NULL
              AND (p.isDeleted IS NULL OR p.isDeleted = false)
            WITH date(datetime({epochMillis: p.createdAt})) AS day,
                 avg(toFloat(p.truthScore)) AS averageScore,
                 count(p) AS count
            ORDER BY day DESC
            LIMIT 7
            RETURN day, averageScore, count
            ORDER BY day ASC
        `);

        const record = summaryResult.records[0];

        res.json({
            success: true,
            total: asNumber(record.get('total')),
            averageScore: asNumber(record.get('averageScore')),
            distribution: {
                reliable: asNumber(record.get('reliable')),
                uncertain: asNumber(record.get('uncertain')),
                lowTrust: asNumber(record.get('lowTrust')),
            },
            trend: trendResult.records.map((r) => ({
                day: r.get('day').toString(),
                averageScore: asNumber(r.get('averageScore')),
                count: asNumber(r.get('count')),
            })),
        });
    } catch (e) {
        console.error('Admin truthness-summary error:', e.message);
        res.status(500).json({
            success: false,
            total: 0,
            averageScore: 0,
            distribution: { reliable: 0, uncertain: 0, lowTrust: 0 },
            trend: [],
        });
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
    // Ensure no double slashes between URL and path
    const baseUrl = AI_SERVICE_URL.endsWith('/') ? AI_SERVICE_URL.slice(0, -1) : AI_SERVICE_URL;
    const safePath = path.startsWith('/') ? path : '/' + path;
    const fullUrl = `${baseUrl}${safePath}`;
    
    console.log(`[Node] Calling AI Service at: ${fullUrl}`);
    
    const res = await fetch(fullUrl, {
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

// ── POST /api/ai/verify ──────────────────────────────────────────────────────
// Verify a claim using Gemini (called on demand from the UI)
app.post('/api/ai/verify', async (req, res) => {
    const { text, imageUrl, isVideo, postId, commentId } = req.body;
    if (!text && !imageUrl) return res.status(400).json({ success: false, message: 'content is required' });

    const session = driver.session();
    try {
        // 1. Check if we have a stored fact-check for this post/comment
        if (postId || commentId) {
            const id = postId || commentId;
            const label = postId ? 'Post' : 'Comment';
            const checkRes = await session.run(
                `MATCH (n:${label} {id: $id}) 
                 RETURN n.truthScore as truthScore, n.truthVerdict as truthVerdict, 
                        n.truthExplanation as truthExplanation, n.truthSources as truthSources`,
                { id }
            );

            if (checkRes.records.length > 0) {
                const record = checkRes.records[0];
                const truthScore = record.get('truthScore');
                if (truthScore !== null) {
                    console.log(`[AI] Returning cached fact-check for ${label} ${id}`);
                    return res.json({
                        success: true,
                        truth_score: truthScore,
                        verdict: record.get('truthVerdict'),
                        explanation: record.get('truthExplanation'),
                        sources: record.get('truthSources')
                    });
                }
            }
        }

        // 2. If no cache, call AI
        const result = await callAI('/analyze/verify', { 
            text: text || "[IMAGE_ONLY_POST]", 
            image_url: imageUrl, 
            is_video: isVideo || false 
        });
        res.json(result);
    } catch (e) {
        console.error('AI verify error:', e.message);
        res.status(503).json({ success: false, message: 'AI service unavailable' });
    } finally {
        await session.close();
    }
});

// ── GET /api/ai/dashboard-sentiment ───────────────────────────────────────────
// Called by the admin dashboard to get platform-wide sentiment + toxicity stats
// Now uses pre-calculated AI flags from Neo4j for instant loading instead of re-analyzing
app.get('/api/ai/dashboard-sentiment', async (req, res) => {
    const session = driver.session();
    try {
        const result = await session.run(`
            MATCH (c:Comment)
            WHERE c.ai_analyzed = true
            WITH count(c) as total,
                 sum(CASE WHEN c.ai_sentiment = 'positive' THEN 1 ELSE 0 END) as pos,
                 sum(CASE WHEN c.ai_sentiment = 'neutral' THEN 1 ELSE 0 END) as neu,
                 sum(CASE WHEN c.ai_sentiment = 'negative' THEN 1 ELSE 0 END) as neg,
                 avg(c.ai_sentiment_score) as avgSentScore,
                 sum(CASE WHEN c.ai_is_toxic = true THEN 1 ELSE 0 END) as toxicCount,
                 avg(c.ai_toxic_score) as avgToxScore,
                 sum(CASE WHEN c.ai_degree = 'extreme' THEN 1 ELSE 0 END) as extremeCount,
                 sum(CASE WHEN c.ai_degree = 'high' THEN 1 ELSE 0 END) as highCount,
                 sum(CASE WHEN c.ai_degree = 'moderate' THEN 1 ELSE 0 END) as modCount,
                 sum(CASE WHEN c.ai_degree = 'low' THEN 1 ELSE 0 END) as lowCount
            RETURN total, pos, neu, neg, avgSentScore, toxicCount, avgToxScore, extremeCount, highCount, modCount, lowCount
        `);

        if (result.records.length === 0 || result.records[0].get('total').toInt() === 0) {
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

        const r = result.records[0];
        const total = r.get('total').toInt();
        const toxicCount = r.get('toxicCount').toInt();

        res.json({
            success: true,
            total: total,
            sentiment: {
                positive: r.get('pos').toInt(),
                neutral: r.get('neu').toInt(),
                negative: r.get('neg').toInt(),
                total: total,
                avg_scores: { positive: r.get('avgSentScore') || 0, neutral: 0, negative: 0 },
                negativity_breakdown: { 
                    low: r.get('lowCount').toInt(), 
                    moderate: r.get('modCount').toInt(), 
                    high: r.get('highCount').toInt(), 
                    extreme: r.get('extremeCount').toInt() 
                }
            },
            toxicity: {
                total: total,
                toxic_count: toxicCount,
                clean_count: total - toxicCount,
                toxic_rate: total > 0 ? toxicCount / total : 0,
                avg_toxic_score: r.get('avgToxScore') || 0,
                degree_breakdown: { 
                    low: r.get('lowCount').toInt(), 
                    moderate: r.get('modCount').toInt(), 
                    high: r.get('highCount').toInt(), 
                    extreme: r.get('extremeCount').toInt() 
                },
                severe_flag_count: r.get('extremeCount').toInt() + r.get('highCount').toInt(),
                category_counts: { "toxic": toxicCount }
            },
            top_toxic_categories: [
                { category: "toxic", count: toxicCount }
            ]
        });

    } catch (e) {
        console.error('AI dashboard-sentiment error:', e.message);
        res.status(503).json({ success: false, message: 'Database error', error: e.message });
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
        console.log(`[AI] Flags stored for comment ${commentId}`);
    } catch (e) {
        // Non-blocking: AI failure should not break comment creation
        console.warn(`[AI] Analysis skipped for comment ${commentId}: ${e.message}`);
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



const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend listening on port ${PORT}`);
    
    // Run background task to analyze any missed/old comments 5 seconds after startup
    setTimeout(autoAnalyzeOldComments, 5000); 
});

// ── Background Task: Analyze Missed Comments ──────────────────────────────────
async function autoAnalyzeOldComments() {
    const session = driver.session();
    try {
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
            console.log("[Background] All comments are already AI-analyzed.");
            return;
        }

        console.log(`[Background] Found ${comments.length} unanalyzed comments. Sending to AI for batch analysis...`);
        
        const aiResponse = await callAI('/analyze/batch/comments', { comments });
        if (!aiResponse.success) throw new Error("AI service returned success: false");

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
                sentiment:      item.sentiment?.label ?? 'neutral',
                sentimentScore: item.sentiment?.confidence ?? 0,
                toxicScore:     item.toxicity?.toxic_score ?? 0,
                isToxic:        item.toxicity?.is_toxic ?? false,
                degree:         item.toxicity?.degree ?? 'low',
            });
        }
        console.log(`[Background] Successfully analyzed and updated ${comments.length} old comments.`);
    } catch (e) {
        console.warn(`[Background] Auto-analysis skipped or failed: ${e.message}`);
    } finally {
        await session.close();
    }
}
