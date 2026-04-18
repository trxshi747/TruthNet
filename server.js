const express = require('express');
const bodyParser = require('body-parser');
const neo4j = require('neo4j-driver');

const app = express();
app.use(bodyParser.json());

// Connect to Neo4j database
const driver = neo4j.driver('bolt://localhost:7687', neo4j.auth.basic('neo4j', 'password'));

app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const session = driver.session();
    const result = await session.run(
      `MATCH (u:User {email: $email, password: $password}) RETURN u`,
      { email, password }
    );
    if (result.records.length > 0) {
      res.json({ message: 'Login successful' });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
    session.close();
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/register', async (req, res) => {
  const { email, password } = req.body;
  try {
    const session = driver.session();
    await session.run(
      `CREATE (:User {email: $email, password: $password})`,
      { email, password }
    );
    session.close();
    res.json({ message: 'Registration successful' });
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
