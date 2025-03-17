# System Patterns

This document outlines the architectural patterns and coding conventions used in this project.

## Architecture

The application uses a layered architecture with BLoC for state management and the Repository pattern for data access. Layers:

1.  **Data Layer:** Retrieves raw data from external sources (database, local storage, API). No domain logic.
2.  **Repository Layer:** Combines data from the Data Layer and applies business rules.  One repository per domain. No Flutter dependencies.
3.  **Business Logic Layer (BLoC):**  Combines repositories, contains feature-specific logic. No Flutter SDK or direct BLoC dependencies.
4.  **Presentation Layer:** UI layer. Uses Flutter to build widgets based on BLoC states. No business logic.

## Barrel Files

Use barrel files to export public-facing files from a feature or package. Create one barrel file per folder, exporting relevant files. A top-level barrel file should export the entire package.

**Caution:** Do not export files intended for internal use only.

BLoCs are typically split into `feature_bloc.dart`, `feature_event.dart`, and `feature_state.dart`. `feature_bloc.dart` often acts as a barrel file using `part of` directives. See [bloc documentation](https://bloclibrary.dev/#/flutterlogintutorial?id=authentication-bloc).

## Project Organization

-   Presentation and state management: `lib/` folder.
-   Data and repository layers: Separate packages (often in their own GitHub repositories).

```
my_app/
  lib/
    feature_name/
      bloc/
        feature_bloc.dart
        feature_event.dart
        feature_state.dart
      view/
        feature_page.dart
  test/
    feature_name/
      bloc/
        feature_bloc_test.dart
        ...
```

Layers should only access the layer directly beneath them.

## BLoC Pattern

-   Each feature has its own BLoC.
-   BLoCs expose streams of states and receive events.

### Event Conventions

Events are named in the **past tense**.

-   Anatomy: `BlocSubject` + `Noun (optional)` + `Verb (event)`
-   Initial load events: `BlocSubject` + `Started`
-   Base event class: `BlocSubject` + `Event`

**Examples:**

-   `CounterIncremented`
-   `HeadlinesFeedLoaded`

### State Conventions

States are nouns. Two approaches:

1.  **Subclasses:**
    -   Anatomy: `BlocSubject` + `Verb (action)` + `State`
    -   `State`: `Initial`, `Success`, `Failure`, `InProgress`
    -   Initial state: `BlocSubject` + `Initial`

2.  **Single Class:**
    -   Anatomy: `BlocSubject` + `State`
    -   Use an enum: `BlocSubject` + `Status` (`initial`, `success`, `failure`, `loading`)
    -   Base state class: `BlocSubject` + `State`

**Examples:**

-   Subclasses: `CounterInitial`, `CounterIncrementedSuccess`
-   Single Class: `CounterState` (with `CounterStatus` enum)

Choose the approach based on whether you need to persist previous data (single class with enum) or have distinct data for each state (sealed/abstract classes).

## Record Types

-   Dart 3.0 record types store multiple values without a separate data class.
-   Always name positional values.

**Example:**

```dart
// Good ✅
Future<(String, String)> getUserNameAndEmail() async => _someApiFetchMethod();

final (username, email) = await getUserNameAndEmail();
```

-   Use dedicated data models for complex scenarios or values used across multiple files.

## Repository Pattern

-   Repositories abstract data sources (e.g., `HtHeadlinesRepository` abstracts `HtInMemoryHeadlinesClient`).
-   Decouples data fetching from UI and business logic.

## Dependency Injection

-   Manual dependency injection is used (e.g., in `main_*.dart` files).
-   Repositories are often provided to BLoCs this way.

## Page/View Pattern

Combine "page" and "view" widgets into a single file.

-   **Page Widget** (`StatelessWidget`):
    -   Provides BLoCs/repositories.
    -   Adds initial events.
    -   Defines the route.
-   **View Widget** (private `StatelessWidget`):
    -   Builds UI based on BLoC state.
    -   Handles user interactions, dispatches events.

## Standalone Widgets

Prefer standalone widgets over helper methods for complex build methods.

-   **Benefits:** Testability, maintainability, reusability, performance.
-   See: [Splitting widgets to methods is a performance anti-pattern](https://www.youtube.com/watch?v=IOyq-eTRhvo&pp=ygUjc3BsaXR0aW5nIHdpZGdldHMgdG8gbWV0aG9kcyBpcyBhIA%3D%3D)

## Error Handling

-   **Document Exceptions:** In function documentation comments.
-   **Define Descriptive Exceptions:** Implement `Exception` with descriptive names.
-   **Document No-Ops:** Comment if a function intentionally does nothing.
-   **Handle Errors in Layers:**
    -   **Data Layer:** `try-catch`, throw custom exceptions.
    -   **Repository Layer:** Catch/handle/re-throw Data Layer exceptions.
    -   **BLoC Layer:** Handle Repository Layer errors, emit states.
    -   **Presentation Layer:** Display user-friendly messages based on BLoC states.

## Routing

-   Uses `go_router`.
-   Structure routes with sub-routes (e.g., `/flutter/news`).
-   Use type-safe routes.
-   Prefer `go` over `push` (except when expecting data from a popped route).
-   Use hyphens in URLs (e.g., `/user/update-address`).
-   Navigate by name over path.
-   Use `BuildContext` extension methods (e.g., `context.goNamed('routeName')`).
-   Path parameters for identifying resources (e.g., `/article/:id`).
-   Query parameters for filtering/sorting (e.g., `/articles?date=2024-03-15`).
-   Avoid `extra` for passing data (doesn't work with deep linking/web).
-   Use redirects for access control.

## Testing

-   Strive for 100% test coverage.
-   Mirror project structure in tests (e.g., `test/models/model_a_test.dart` for `lib/models/model_a.dart`).
-   Use `expect` or `verify` for assertions.
-   Use matchers (e.g., `expect(value, equals(expectedValue))`).
-   Use string expressions for types in descriptions (e.g., `testWidgets('renders $MyWidget', ...)`, but `group(MyWidget, ...)`).
-   Descriptive test names.
-   One scenario per test.
-   Prefer finding widgets by type (`find.byType(MyWidget)`).
-   Use private mocks.
-   Split tests into groups.
-   Keep test setup inside groups.
-   Initialize shared mutable objects per test (`setUp`).
-   Use constants for test tags.
-   No shared state between tests.
-   Use random test ordering (`flutter test --test-randomize-ordering-seed random`).
-   Include accessibility testing.

## Code Commenting and Documentation

- Add documentation comments (///) to all public functions, classes, and significant code elements.
- Add inline comments (//) to explain any complex logic or non-obvious code blocks.

## Accessibility

- Ensure the UI is accessible to users with disabilities.
- Provide sufficient color contrast and use readable font sizes.
- Adhere to accessibility guidelines, including semantic structure (`Semantics`, `MergeSemantics`).
- Implement proper focus management for keyboard users.
- Provide clear visual cues for the currently focused element.

## Theming

-   Use `ThemeData`.
-   Access theme values **exclusively** with `Theme.of(context)` (e.g., `Theme.of(context).primaryColor`). **Do not introduce hardcoded color values.**
-   Emphasize a minimalist approach, avoiding excessive use of colors and gradients.
- The UI must adapt to both light and dark themes.
-   Typography:
    -   Import fonts, declare in `pubspec.yaml`.
    -   Use `flutter_gen` for type-safe access.
    -   Create custom text styles (`AppTextStyle`).
    -   Use `TextTheme`.
    -   Establish a clear visual hierarchy using font sizes, weights, line height, letter spacing, and text alignment. Optimize for readability.
-   Colors:
    -   Create custom colors (`AppColors`).
    -   Use `ColorScheme` to define component colors, using theme-based colors.
    - Use the `accentColor` sparingly for key interactive elements or important information.
-   Use component themes (e.g., `FilledButtonThemeData`).
-   Define spacing constants (`AppSpacing`).

## Localization

- All hardcoded text in the UI must be localized using the `l10n` feature.
- Reference the `lib/l10n/` directory for localization files.
- UI code should only include localized variables, not hardcoded strings.

## Layouts

-   Constraints flow down, sizes go up, parent sets position.

### Whitespace

- Utilize whitespace (padding, margin, spacing) as a key design element to create visual balance, improve readability, and group related content.

### Rows and Columns

-   `Row`: Horizontal layout.
-   `Column`: Vertical layout.
-   `MainAxisSize`: Space along main axis (`min`, `max`).
-   `MainAxisAlignment`: Child positioning along main axis (`start`, `end`, `center`, `spaceAround`, `spaceBetween`, `spaceEvenly`).
-   `CrossAxisAlignment`: Child positioning along cross axis (`start`, `end`, `center`, `stretch`).

### Expanded, Flexible, and Spacer

-   Use within `Row` and `Column` to control space sharing.
-   `Expanded`: Child fills available space.
-   `Spacer`: Empty space filling available space.
-   `Flexible`: Like `Expanded`, but with `FlexFit` (`tight` or `loose`).
-   `flex` factor: Relative size of widgets.

### Wrap and ListView

-   `Wrap`: Wraps children to the next line/column on overflow.
-   `ListView`: Scrollable list.
    -   `scrollDirection`: Scrolling direction.
    -   `shrinkWrap`: `ListView` takes only needed space.

-   `SingleChildScrollView`: Makes a single widget scrollable. Prefer `ListView` for lists.

### Responsive and Adaptive Design

- Design the UI to be responsive and adapt to different screen sizes and orientations.
- Use `LayoutBuilder` to get the constraints of the current widget and build different UIs based on those constraints.
- Consider using `TwoPane` for large screens (e.g., tablets, foldables) to display two views side-by-side.
- Use `AdaptiveGridView` for creating grids that adapt to different screen sizes.
- Support both RTL (right-to-left) and LTR (left-to-right) layouts.
    - Use the `Directionality` widget to specify the text direction.
    - Use logical properties (e.g., `EdgeInsetsDirectional` instead of `EdgeInsets.only(left:...)`).
    - Prefer widgets that use `start` and `end` instead of `left` and `right`.
    - Consider mirroring icons or images when appropriate.
    - Ensure correct text alignment.

- Avoid using `Expanded` inside `Wrap`, `ListView`, and `SingleChildScrollView` unless the nested widget has a fixed size.
