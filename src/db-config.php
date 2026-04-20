<?php
$dbHost = '##DB_HOST##';
$dbName = 'blog';
$dbUser = '##DB_USER##';
$dbPass = '##DB_PASSWORD##';

$dbHostPlaceholder = '##DB' . '_HOST##';
$dbUserPlaceholder = '##DB' . '_USER##';
$dbPassPlaceholder = '##DB' . '_PASSWORD##';

// Local fallback when the app is run outside Terraform/AWS.
if ($dbHost === $dbHostPlaceholder) {
    $dbHost = getenv('DB_HOST') ?: '127.0.0.1';
}

if ($dbUser === $dbUserPlaceholder) {
    $dbUser = getenv('DB_USER') ?: 'root';
}

if ($dbPass === $dbPassPlaceholder) {
    $dbPass = getenv('DB_PASS') ?: '';
}

define('DB_HOST', $dbHost);
define('DB_NAME', $dbName);
define('DB_USER', $dbUser);
define('DB_PASS', $dbPass);
define('DB_DSN', sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', DB_HOST, DB_NAME));
define('DB_ADMIN_DSN', sprintf('mysql:host=%s;charset=utf8mb4', DB_HOST));

$options = array(
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_EMULATE_PREPARES => false
);

$sslCaPath = '/etc/pki/rds/global-bundle.pem';
if ($dbHost !== '127.0.0.1' && $dbHost !== 'localhost' && file_exists($sslCaPath)) {
    $options[PDO::MYSQL_ATTR_SSL_CA] = $sslCaPath;
}

function createPdo(string $dsn): PDO
{
    global $options;

    return new PDO($dsn, DB_USER, DB_PASS, $options);
}

function databaseExists(PDO $pdo): bool
{
    $statement = $pdo->prepare('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = :schema_name');
    $statement->execute(array('schema_name' => DB_NAME));

    return (int) $statement->fetchColumn() > 0;
}

function articlesTableExists(PDO $pdo): bool
{
    $statement = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = :schema_name AND table_name = :table_name'
    );
    $statement->execute(array(
        'schema_name' => DB_NAME,
        'table_name' => 'articles'
    ));

    return (int) $statement->fetchColumn() > 0;
}

function loadSqlStatements(string $path): array
{
    $sql = @file_get_contents($path);
    if ($sql === false) {
        throw new RuntimeException(sprintf('Unable to read SQL bootstrap file: %s', $path));
    }

    $sql = preg_replace('/^\xEF\xBB\xBF/', '', $sql);
    $statements = preg_split('/;\s*(?:\r\n|\r|\n|$)/', $sql);

    return array_values(array_filter(array_map('trim', $statements), static function ($statement) {
        return $statement !== '';
    }));
}

function runSqlFile(PDO $pdo, string $path): void
{
    foreach (loadSqlStatements($path) as $statement) {
        $pdo->exec($statement);
    }
}

function ensureSchema(): void
{
    static $initialized = false;

    if ($initialized) {
        return;
    }

    $bootstrapPdo = createPdo(DB_ADMIN_DSN);
    if (!databaseExists($bootstrapPdo) || !articlesTableExists($bootstrapPdo)) {
        runSqlFile($bootstrapPdo, __DIR__ . DIRECTORY_SEPARATOR . 'articles.sql');
    }

    $initialized = true;
}

function getPDO(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    ensureSchema();
    $pdo = createPdo(DB_DSN);

    return $pdo;
}
