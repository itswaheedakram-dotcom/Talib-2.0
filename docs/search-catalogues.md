# Extensible global search

SearchRegistry registers built-in adapters and reads enabled `searchCatalogs` descriptors. A new public catalogue needs no search screen, parser enum or routing edits when it uses the shared contract. Super admin can register and publish it under Admin → Catalogue registry. Search observes the public registry live; adding, editing or disabling a descriptor updates categories without restarting the app. Retry reconnects after a registry network failure. Listing pages use their scoped cache. Drafts and disabled catalogues are not searchable. Demo never reads or publishes live catalogue data.

Descriptor document `searchCatalogs/transport`:

```json
{"label":"Transport","icon":"category","aliases":["bus","buses"],"facets":[{"key":"mode","label":"Mode","type":"choice"}],"enabled":true}
```

Listing document `catalogItems/<stable-id>`:

```json
{"catalogId":"transport","title":"Campus shuttle","description":"Public schedule","city":"Lahore","area":"Johar Town","tags":["bus"],"attributes":{"mode":"Shared","schedule":{"days":["Monday","Tuesday"]}},"published":true}
```

Both writes require `updatedAt: serverTimestamp()`. Arbitrary **public** maps/lists/scalars are searchable and rendered by the generic detail screen. Facet types are choice, number (upper bound), toggle; keys may use dot notation for nested attributes. Do not put phone numbers, private owner details, unpublished documents, admin evidence or secrets in public attributes. Descriptor does not accept a collection path or executable route.

Existing independent collections need a SearchAdapter that converts approved public records to SearchRecord, implements pagination and registers with SearchEngine. A new database collection with an unknown schema cannot safely be indexed automatically. Prefer the common collection for future catalogue types.

Search fetches pages of 200 per supported Firestore source, then ranks locally, with a 60-second scoped cache (public people are rechecked each submit). Results count describes loaded records; '+' means more pages exist. Load more continues discovery; it is not an exhaustive server-side full-text index. Institute/program and opportunity sources use their existing repository loaders. Consider a server-side indexed search service when volume exceeds local ranking capacity.

Shared queries require the composite index catalogId ASC, published ASC, document ID ASC. The repository includes its index configuration. Sorting is across loaded results, not unseen pages.

Courses, scholarships, jobs, internships and seminars use this same engine in real mode. Their existing sample module screens and searchable sample fixtures are isolated to Demo mode. Real jobs, internships and seminars become available by publishing their shared catalogue records; samples are never promoted into production.
