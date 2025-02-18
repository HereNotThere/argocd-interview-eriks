import { Client, DatabaseError } from 'pg'
import { z } from 'zod'

const envSchema = z.object({
    TARGET_DB_HOST: z.string().min(1),
    TARGET_DB_DATABASE: z.string().min(1),
    TARGET_DB_ROOT_USER: z.string().min(1),
    TARGET_DB_ROOT_PASSWORD: z.string().min(1),
    TARGET_DB_APP_USER: z.string().min(1),
    TARGET_DB_APP_PASSWORD: z.string().min(1),
})

const env = envSchema.parse(process.env)

function isDBAlreadyExistsError(e: unknown) {
    return e instanceof DatabaseError && (e.code == '42P04' || e.code == '23505')
}

const createSchema = async () => {
    const schemaName = 'notification_service'
    // create schema if not exists
    console.log('creating schema')

    let error

    const pgClient = new Client({
        host: env.TARGET_DB_HOST,
        database: env.TARGET_DB_DATABASE,
        password: env.TARGET_DB_APP_PASSWORD,
        user: env.TARGET_DB_APP_USER,
        port: 5432,
        ssl: {
            rejectUnauthorized: false,
        },
    })

    try {
        console.log('connecting')
        await pgClient.connect()
        console.log('connected')

        const createSchemaQuery = `
      DO
      $do$
      BEGIN
        IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_namespace WHERE nspname = '${schemaName}'
        ) THEN
          CREATE SCHEMA ${schemaName};
        END IF;
      END
      $do$
    `
        await pgClient.query(createSchemaQuery)
        console.log('done creating schema')
    } catch (e) {
        console.error('error creating schema: ', e)
        error = e
    } finally {
        await pgClient.end()
    }

    if (error) {
        throw error
    }
}

const createNotificationServiceDbUser = async () => {
    console.log('creating notification service db user')

    const pgClient = new Client({
        host: env.TARGET_DB_HOST,
        database: 'postgres',
        password: env.TARGET_DB_ROOT_PASSWORD,
        user: env.TARGET_DB_ROOT_USER,
        port: 5432,
        ssl: {
            rejectUnauthorized: false,
        },
    })

    let error

    try {
        console.log('connecting')
        await pgClient.connect()
        console.log('connected')

        // create user if not exists
        console.log('creating user')

        const createUserQuery = `
      DO
      $do$
      BEGIN
        IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_user WHERE usename = '${env.TARGET_DB_APP_USER}'
        ) THEN
          CREATE USER ${env.TARGET_DB_APP_USER} WITH PASSWORD '${env.TARGET_DB_APP_PASSWORD}';
        END IF;
      END
      $do$
    `

        await pgClient.query(createUserQuery)
        console.log('created user')

        try {
            console.log('creating database')
            const createDatabaseQuery = `CREATE DATABASE ${env.TARGET_DB_DATABASE};`
            await pgClient.query(createDatabaseQuery)
            console.log('created database')
        } catch (e) {
            if (isDBAlreadyExistsError(e)) {
                console.log('database already exists')
            } else {
                console.error('error creating database: ', e)
                throw e
            }
        }

        console.log('granting create schema to user')

        await pgClient.query('SELECT pg_advisory_lock(1);') // 1 is an arbitrary lock ID
        const grantCreateSchemaQuery = `
      GRANT CREATE ON DATABASE ${env.TARGET_DB_DATABASE} TO ${env.TARGET_DB_APP_USER};
    `

        // run the query above with 5 retry attempts:
        const executeCreateQuery = async () => {
            let attempt = 0
            let error
            while (attempt < 5) {
                try {
                    await pgClient.query(grantCreateSchemaQuery)
                    break
                } catch (e) {
                    console.warn(`error executing create query attempt: ${attempt}`, e)
                    error = e
                    attempt++
                }
            }
            if (error) {
                throw error
            }
        }

        await executeCreateQuery()

        console.log('done creating user')
    } catch (e) {
        error = e
    } finally {
        await pgClient.query('SELECT pg_advisory_unlock(1);')
        await pgClient.end()
    }

    if (error) {
        throw error
    }
}

export const run = async () => {
    await createNotificationServiceDbUser()
    await createSchema()

    console.log('success')
}

run().catch((e) => {
    console.error('error: ', e)
    process.exit(1)
})
