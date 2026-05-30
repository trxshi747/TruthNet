const neo4j = require('neo4j-driver');
const bcrypt = require('bcryptjs');
const { randomUUID } = require('crypto');
require('dotenv').config();

//console.log("USER =", process.env.NEO4J_USER);
//console.log("PASSWORD =", process.env.NEO4J_PASSWORD);

const driver = neo4j.driver(
    'bolt://localhost:7687',
    neo4j.auth.basic(
        process.env.NEO4J_USER,
        process.env.NEO4J_PASSWORD
    )
);

async function initializeFirstAdmin() {
    const session = driver.session();

    try {

        // Vérifie si un admin existe déjà
        const adminCheck = await session.run(`
            MATCH (u:User)-[:HAS_ROLE]->(:Role {name:'Admin'})
            RETURN u
            LIMIT 1
        `);

        if (adminCheck.records.length > 0) {
            console.log('✅ Un administrateur existe déjà');
            return;
        }

        // Création du rôle Admin si absent
        await session.run(`
            MERGE (r:Role {name:'Admin'})
            ON CREATE SET
                r.id = randomUUID(),
                r.description = 'Administrateur système'
        `);

        console.log('🚀 Création du premier administrateur...');

        const hashedPassword = await bcrypt.hash(
            'Admin123!',
            10
        );

        await session.run(`
            MATCH (r:Role {name:'Admin'})

            CREATE (u:User:AuthenticatedUser:Administrator {
                id: randomUUID(),
                firstName: 'System',
                lastName: 'Admin',
                username: 'SuperAdmin',
                email: 'admin@truthnet.com',
                password: $password,
                status: 'ACTIVE',
                registrationDate: timestamp()
            })

            CREATE (u)-[:HAS_ROLE]->(r)

            RETURN u
        `, {
            password: hashedPassword
        });

        console.log('━━━━━━━━━━━━━━━━━━━━━━');
        console.log('✅ Administrateur créé');
        console.log('Email : admin@truthnet.com');
        console.log('Password : Admin123!');
        console.log('━━━━━━━━━━━━━━━━━━━━━━');

    } catch (error) {
        console.error('❌ Erreur :', error);
    } finally {
        await session.close();
        await driver.close();
    }
}

initializeFirstAdmin();