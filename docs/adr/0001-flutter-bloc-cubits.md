# 0001. State management: flutter_bloc Cubits

- Status: Accepted
- Date: 2026-09-20
- Phase: P0

## Context

The app has two stateful flows: authentication (login, logout, session restore) and listings (loading, empty, error, refresh). An early draft of the plan used Provider in its body but locked BLoC in its summary, so an agent could have picked either. `docs/q-and-a.md` recommended BLoC.

## Decision

Use flutter_bloc **Cubits** (`AuthCubit`, `ListingsCubit`), wired with `BlocProvider` and `RepositoryProvider`. Test them with `bloc_test`.

## Alternatives rejected

- **Provider / ChangeNotifier**: fine for an app this size, but state changes are harder to assert in tests, and it contradicted the recommendation already given to the reviewer.
- **Riverpod**: capable, but a second paradigm for a reviewer to read, with no benefit at this scope.
- **Full Bloc (events)**: event classes add ceremony that two simple flows don't need. A Cubit can be promoted to a Bloc later if needed.

## Consequences

- Every state transition can be tested with `bloc_test` without widgets.
- Adds `flutter_bloc` and `bloc_test` as dependencies.
- Agents must not introduce Provider or Riverpod (the `AGENTS.md` rule).
