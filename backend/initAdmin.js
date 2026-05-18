const neo4j = require('neo4j-driver');
const bcrypt = require('bcryptjs');
require('dotenv').config();
const { randomUUID } = require('crypto');

// NEO4J CONNECTION
const driver = neo4j.driver(
    'bolt://localhost:7687',
    neo4j.auth.basic(process.env.NEO4J_USER, process.env.NEO4J_PASSWORD)
);

async function initializeFirstAdmin() {
    const session = driver.session();

    try {
        // 1. Vérifier si un admin existe déjà
        const adminCheck = await session.run(
            `MATCH (u:User)-[:HAS_ROLE]->(r:Role {name: 'Admin'})
             RETURN u
             LIMIT 1`
        );

        if (adminCheck.records.length > 0) {
            console.log('Un administrateur existe déjà');
            return;
        }

        // 2. Vérifier si le rôle "Admin" existe, sinon le créer
        const roleCheck = await session.run(
            `MATCH (r:Role {name: 'Admin'}) RETURN r`
        );

        let roleId;
        if (roleCheck.records.length === 0) {
            // Créer le rôle Admin
            const roleResult = await session.run(
                `CREATE (r:Role {name: 'Admin', description: 'Administrateur système'})
                 RETURN r`
            );
            roleId = roleResult.records[0].get('r').properties.id;
        }

        // 3. Créer l'utilisateur admin
        console.log('Création du premier administrateur...');

        const hashedPassword = await bcrypt.hash('Admin123!', 10);
        const adminId = randomUUID();
        const createdAt = new Date().toISOString();

        // Créer l'utilisateur
        const userResult = await session.run(
            `CREATE (u:User {
                id: $id,
                name: $name,
                username: $username,
                email: $email,
                password: $password,
                status: $status,
                createdAt: $createdAt

             })
             RETURN u`,
            {
                id: adminId,
                name: 'Admin',
                username: 'SuperAdmin',
                email: 'admin@truthnet.com',
                password: hashedPassword,
                status: 'Active',
                createdAt: createdAt
            }
        );
 
        // 4. Créer la relation HAS_ROLE
        await session.run(
            `MATCH (u:User {id: $userId})
             MATCH (r:Role {name: 'Admin'})
             CREATE (u)-[:HAS_ROLE]->(r)`,
            { userId: adminId }
        );

        console.log('Administrateur créé avec succès !');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('Email: admin@truthnet.com');
        console.log('Mot de passe: Admin123!');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    } catch (error) {
        console.error('Erreur:', error);
    } finally {
        await session.close();
        await driver.close();
    }
}


// Exécuter le script
initializeFirstAdmin();