# Architecture

Phase 1 creates a lean SwiftUI app target plus sibling Swift Package modules.

- `ColombaCustomer/`: app lifecycle, routing, environment, root composition only.
- `Packages/ColombaCore`: shared models, state, telemetry, performance, errors.
- `Packages/ColombaDesign`: locked design tokens and reusable design primitives.
- `Packages/ColombaNetworking`: API client, endpoints, DTOs, authenticated session.
- `Packages/ColombaAuth`: Phase 2 authentication implementation.
- `Packages/ColombaBilling`: Phase 4 Stripe portal and billing models.
- `Packages/Features/*Feature`: feature modules filled in later phases.

Rule: the app target composes packages; business logic belongs in packages.
