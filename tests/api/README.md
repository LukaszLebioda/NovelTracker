# API tests (Postman / Newman)

The API test suite is a Postman collection executed with
[Newman](https://github.com/postmanlabs/newman).

## Files

- `noveltracker.postman_collection.json` — the collection (currently a single
  `GET {{baseUrl}}/health` request).

## Run

The API server must be running first (`npm run dev:server` from the repo root).

From the repo root:

```bash
npm run test:api
```

Or directly with Newman, pointing at a running server:

```bash
npx newman run tests/api/noveltracker.postman_collection.json \
  --env-var baseUrl=http://localhost:3000
```

`baseUrl` defaults to `http://localhost:3000` in the `test:api` script; override
it with `--env-var baseUrl=<url>` (for example, a CI or Docker URL).
