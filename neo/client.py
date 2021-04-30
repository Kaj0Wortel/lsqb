from neo4j import GraphDatabase, unit_of_work
import time
import sys

@unit_of_work(timeout=300)
def query_fun(tx, query):
    result = tx.run(query)
    return result.single()

def run_query(session, sf, query_id, query_spec, results_file):
    start = time.time()
    result = session.read_transaction(query_fun, query_spec)
    end = time.time()
    duration = end - start
    results_file.write(f"Neo4j\t\t{sf}\t{query_id}\t{duration:.4f}\t{result[0]}\n")
    results_file.flush()
    return (duration, result)

if len(sys.argv) < 2:
    print("Usage: client.py sf")
    print("where sf is the scale factor")
    exit(1)
else:
    sf = sys.argv[1]

driver = GraphDatabase.driver("bolt://localhost:7687")
session = driver.session()

#with open(f"results/results.csv", "a+") as results_file:
with sys.stdout as results_file:
    for i in range(1, 10):
        with open(f"cypher/q{i}.cypher", "r") as query_file:
            run_query(session, sf, i, query_file.read(), results_file)

session.close()
driver.close()
