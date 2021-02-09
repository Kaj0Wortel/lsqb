MATCH (country:Country)
MATCH (pA:Person)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(country)
MATCH (pB:Person)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(country)
MATCH (pC:Person)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(country)
MATCH (pA)-[k1:KNOWS]-(pB)-[k2:KNOWS]-(pC)-[k3:KNOWS]-(pA)
RETURN count(*) AS count
