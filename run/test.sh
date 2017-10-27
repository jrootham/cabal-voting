
PASSWORD=$1
export JDBC_DATABASE_URL="jdbc:postgresql://localhost:5432/voting_test?user=jrootham&password=$PASSWORD"
export PORT=8040

pushd ~/dev/voting-server
lein run
popd


