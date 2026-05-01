# Architecture

This document is a lightweight map for future Colomba iOS contributors. Keep it updated as the app structure evolves.

## App structure

### `Features/`

Feature modules should own user-facing flows and screen-level behavior. Prefer small feature folders with local view models, models, and UI state where practical.

### `Services/`

Service types should wrap external systems and side effects such as networking, voice/AI integrations, analytics, authentication, and backend APIs. Keep protocol boundaries clear so features can be tested without live services.

### `Persistence/`

Persistence should contain local storage, cache, database, and migration code. Keep data transformations explicit and avoid leaking storage-specific models into UI layers.

### `UI/`

Shared UI components, design-system primitives, styling helpers, and reusable view utilities belong here. Feature-specific UI should stay close to the feature unless it is reused broadly.

## Maintenance notes

- Keep business rules out of views when possible.
- Prefer dependency injection for services and persistence boundaries.
- Document new top-level folders in this file when they are introduced.
- Avoid committing machine-specific Xcode or simulator settings.
