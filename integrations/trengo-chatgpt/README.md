# Trengo inside ChatGPT

A private Custom GPT Action that connects directly to Trengo; no hosting, middleware or separate OpenAI API key required. Requires access to GPT creation and Actions in your ChatGPT plan/workspace.

## Setup

1. Create a personal access token in Trengo's settings. Use the least-privileged account available. Do not paste the token into a chat, these files or Git.
2. Open <https://chatgpt.com/gpts/editor> and create a GPT named **Trengo Assistant**.
3. In **Configure → Instructions**, paste `instructions.md`.
4. Under **Actions → Create new action**, paste `openapi.json` into the schema editor.
5. Set **Authentication → API Key → Bearer**. Paste the token itself, without the `Bearer ` prefix, into the authentication field.
6. Test `searchContacts` with a known contact, `listTickets` with that contact's ID, and `listTicketMessages` with a returned ticket ID. Approve the connection to `app.trengo.com` when prompted.
7. Save the GPT with **Only me** visibility. Do not publish it or share its credentials. For team use, design per-user authentication/access controls first; a shared token is not per-user authorization.

Suggested prompts:

- “Find the contact with email alice@example.com and summarize their latest ticket.”
- “Show unresolved tickets, including both open and assigned tickets.”
- “Summarize ticket 12345 and draft a reply. Do not send it.”

## Scope and safety

The schema exposes only GET operations: contact search, ticket listing and ticket messages. It cannot send replies or modify tickets. This is a schema-level restriction, **not** a read-only permission imposed on the Trengo token; a stolen token may have write access. Revoke it in Trengo if exposed.

Trengo content, including customer data and internal notes, is transmitted to ChatGPT when retrieved. Use an approved account/workspace and data-handling settings. Retrieved messages can contain malicious instructions; the GPT instructions explicitly treat them as untrusted, but this is not a security boundary.

Contact search supports name, phone and email. The documented ticket-list endpoint does not offer full-text search. Results are paginated; large responses may exceed ChatGPT Action limits. Narrow filters where possible. Trengo documents a limit of 120 API requests/minute.

## Validation and troubleshooting

The schema is based on the official endpoints below. Local OpenAPI validation does not prove the ChatGPT importer or authenticated calls work; complete step 6 before relying on it.

- **401:** replace the token in Action authentication.
- **403:** verify that the token's account can access the requested data.
- **429:** wait for the server's `Retry-After` interval.
- **HTML/non-JSON response:** Trengo documents `Accept: application/json` and `Content-Type: application/json` headers. Check the Action test's actual response. If the direct Action does not negotiate JSON correctly, it will need a proxy that sets those headers; this package does not include one.
- **Actions unavailable:** check plan/workspace permissions and allowed Action domains; allow `app.trengo.com` if your administrator approves.

Sources:

- [Authentication, headers and rate limits](https://developers.trengo.com/docs/rate-limiting)
- [Contact search](https://developers.trengo.com/reference/list-all-contacts)
- [Ticket listing](https://developers.trengo.com/reference/list-all-tickets)
- [Ticket messages](https://developers.trengo.com/reference/list-all-messages)
