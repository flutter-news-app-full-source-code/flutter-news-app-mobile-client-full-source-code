# System Patterns

## Architecture and Layering

The application follows a layered architecture to build highly scalable, maintainable, and testable apps. This architecture leverages the BLoC (Business Logic Component) pattern for state management and the Repository pattern for data access. It consists of four layers: the data layer, the repository layer, the business logic layer, and the presentation layer. Each layer has a single responsibility, and there are clear boundaries between each one. This layered approach significantly enhances the developer experience by allowing independent development, simplified testing (since only one layer needs to be mocked at a time), and streamlined code reviews due to clarified component ownership.

### Data Layer

This is the lowest layer, responsible for retrieving raw data from external sources (e.g., SQLite database, local storage, RESTful API) and making it available to the Repository Layer. It should be free of any domain or business logic.

### Repository Layer

This layer composes one or more data clients from the Data Layer and applies "business rules" (domain-specific logic) to the data. A separate repository is created for each domain (e.g., user repository, weather repository).  Packages in this layer should not import any Flutter dependencies and not be dependent on other repositories. This layer can be considered the "product" layer, where business rules determine how to combine data into valuable units for the customer.

### Business Logic Layer

This layer composes one or more repositories and contains the logic for specific features or use-cases. It uses the bloc library to retrieve data from the Repository Layer and provide new states to the Presentation Layer. It should have no dependency on the Flutter SDK and no direct dependencies on other business logic components. This is the "feature" layer, where design and product determine how a feature functions.

### Presentation Layer

This is the top layer, the UI layer where Flutter is used to "paint pixels" on the screen. No business logic should exist here. It interacts only with the Business Logic Layer, building widgets and managing their lifecycle based on the state provided by the BLoCs. This is the "design" layer, focusing on user interface and experience.

## Barrel Files

When building a package, feature, or API, a folder structure contains all the source code. Without exporting required files, developers face long and messy import sections. Refactoring file names in one feature would also require changes in other places, which can be avoided with barrel files.

A feature might look like this:

```
my_feature/
  bloc/
    feature_bloc.dart
    feature_event.dart
    feature_state.dart
  view/
    feature_page.dart
    feature_view.dart
  widgets/
    widget_1.dart
    widget_2.dart
```

To use `widget_1.dart` and `widget_2.dart` elsewhere, separate imports would be needed:

```dart
import 'package:my_package/lib/src/widgets/widget_1';
import 'package:my_package/lib/src/widgets/widget_2';
```

Barrel files solve this inefficiency. They export public-facing files, making them available to the rest of the app. Create one barrel file per folder, exporting all files required elsewhere. A top-level barrel file should also export the package as a whole.

With barrel files, the feature structure becomes:

```
my_feature/
  bloc/
    feature_bloc.dart
    feature_event.dart
    feature_state.dart
  view/
    feature_page.dart
    feature_view.dart
    view.dart
  my_feature.dart
```

The `view.dart` barrel file would contain:

```dart
export 'feature_page.dart';
export 'feature_view.dart';
```

**Caution:** Not all files should be exported. Files used internally within the same folder, but not intended for public use, should not be in the barrel file.

By convention, BLoCs are typically broken into separate files for events, states, and the BLoC itself:

```
bloc/
  feature_bloc.dart
  feature_event.dart
  feature_state.dart
```

In this case, `feature_bloc.dart` acts as a barrel file due to `part of` directives. See the [bloc documentation](https://bloclibrary.dev/#/flutterlogintutorial?id=authentication-bloc) for details.

> Tip: The [VSCode extension](https://github.com/orestesgaolin/dart-export-index) can help automate exporting files in a folder or adding a file to the barrel file.

### Project Organization and Dependency Graph

The presentation layer and state management live in the project's `lib` folder. The data and repository layers are typically separate packages, hosted in their own GitHub repositories and imported into this project.

```
my_app/
  lib/
    login/
      bloc/
        login_bloc.dart
        login_event.dart
        login_state.dart
      view/
        login_page.dart
        view.dart
  test/
    login/
      bloc/
        login_bloc_test.dart
        login_event_test.dart
        login_state_test.dart
      view/
        login_page_test.dart
```

Each layer abstracts the underlying layers' implementation details. Avoid indirect dependencies. The Repository Layer shouldn't know *how* the Data Layer fetches data, and the Presentation Layer shouldn't directly access values from Shared Preferences. Implementation details should not leak between layers.

Data should flow from the bottom up, and a layer can only access the layer directly beneath it.  The `LoginPage` should never directly access the `ApiClient`, and the `ApiClient` should not depend on the `UserRepository`. This ensures each layer has a specific responsibility and can be tested in isolation.

Good ✅

```dart
class LoginPage extends StatelessWidget {
    ...
    LoginButton(
        onPressed: => context.read<LoginBloc>().add(const LoginSubmitted());
    )
    ...
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
    ...
    Future<void> _onLoginSubmitted(
        LoginSubmitted event,
        Emitter<LoginState> emit,
    ) async {
        try {
            await _userRepository.logIn(state.email, state.password);
            emit(const LoginSuccess());
        } catch (error, stackTrace) {
            addError(error, stackTrace);
            emit(const LoginFailure());
        }
    }
}

class UserRepository {
    const UserRepository(this.apiClient);

    final ApiClient apiClient;

    final String loginUrl = '/login';

    Future<void> logIn(String email, String password) {
        await apiClient.makeRequest(
            url: loginUrl,
            data: {
                'email': email,
                'password': password,
            },
        );
    }
}
```

Bad ❗️

```dart
class LoginPage extends StatelessWidget {
    ...
    LoginButton(
        onPressed: => context.read<LoginBloc>().add(const LoginSubmitted());
    )
    ...
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
    ...

    final String loginUrl = '/login';

    Future<void> _onLoginSubmitted(
        LoginSubmitted event,
        Emitter<LoginState> emit,
    ) async {
        try {
            await apiClient.makeRequest(
                url: loginUrl,
                data: {
                    'email': state.email,
                    'password': state.password,
                },
        );

        emit(const LoginSuccess());
        } catch (error, stackTrace) {
            addError(error, stackTrace);
            emit(const LoginFailure());
        }
    }
}
```

In this example, the API implementation details are now leaked and made known to the bloc. The API's login url and request information should only be known to the `UserRepository`. Also, the `ApiClient` instance will have to be provided directly to the bloc. If the `ApiClient` ever changes, every bloc that relies on the `ApiClient` will need to be updated and retested.

## BLoC Pattern and State Handling

BLoC (Business Logic Component) is used to manage the application's state and handle user interactions. Each feature typically has its own BLoC (e.g., `HeadlinesFeedBloc`). BLoCs expose streams of states and receive events as input. The `AppBlocObserver` (not detailed here, but mentioned in the original document) provides centralized logging for BLoC changes and errors.

The following naming conventions are strongly recommended.

### Event Conventions

Events should be named in the **past tense** because events are things that have already occurred from the bloc's perspective.

#### Anatomy

`BlocSubject` + `Noun (optional)` + `Verb (event)`

Initial load events should follow the convention: `BlocSubject` + `Started`

The base event class should be named: `BlocSubject` + `Event`.

#### Examples

✅ **Good**

*   `CounterIncremented`
*   `HeadlinesFeedLoaded`
*   `UserLoginSubmitted`

❌ **Bad**

*   `IncrementCounter`
*   `LoadHeadlines`
*   `SubmitLogin`

### State Conventions

States should be nouns because a state is just a snapshot at a particular point in time. There are two common ways to represent state: using subclasses or using a single class.

#### Anatomy

##### Subclasses

`BlocSubject` + `Verb (action)` + `State`

When representing the state as multiple subclasses `State` should be one of the following:

`Initial` | `Success` | `Failure` | `InProgress`

Initial states should follow the convention: `BlocSubject` + `Initial`.

##### Single Class

`BlocSubject` + `State`

When representing the state as a single base class an enum named `BlocSubject` + `Status` should be used to represent the status of the state:

`initial` | `success` | `failure` | `loading`.

The base state class should always be named: `BlocSubject` + `State`.

#### Examples

✅ **Good**

##### Subclasses

*   `CounterInitial`
*   `CounterIncrementedSuccess`
*   `HeadlinesFeedLoadFailure`
*   `UserLoginSuccess`

##### Single Class

*   `CounterState` (with `CounterStatus` enum)
*   `HeadlinesFeedState` (with `HeadlinesFeedStatus` enum)
*  `UserState` (with `UserStatus` enum)

❌ **Bad**

##### Subclasses
*   `CounterIncrementing`
*   `HeadlinesFeedLoad`
*    `LoginUser`

##### Single Class
*   `Counter`
*   `Headlines`
*   `Login`

There are two main approaches to handling states emitted from BLoCs:

1.  **Enum for Status within a Single State Class:** Useful for persisting previous data while updating specific fields. Common in scenarios like forms or incremental loading.

    **Example:**

    ```dart
    enum CreateAccountStatus { initial, loading, success, failure }

    class CreateAccountState extends Equatable {
      const CreateAccountState({
        this.status = CreateAccountStatus.initial,
        this.name,
        this.surname,
        this.email,
      });

      final CreateAccountStatus status;
      final String? name;
      final String? surname;
      final String? email;

      CreateAccountState copyWith({
        CreateAccountStatus? status,
        String? name,
        String? surname,
        String? email,
      }) {
        return CreateAccountState(
          status: status ?? this.status,
          name: name ?? this.name,
          surname: surname ?? this.surname,
          email: email ?? this.email,
        );
      }

      @override
      List<Object> get props => [status, name, surname, email];
    }
    ```

    **UI Consumption (using `BlocListener`):**

    ```dart
    BlocListener<CreateAccountCubit, CreateAccountState>(
      listener: (context, state) {
        if (state.status == CreateAccountStatus.failure) {
          // Show error message
        }
        if (state.status == CreateAccountStatus.success) {
          // Show success message
        }
      },
      child: CreateAccountFormView(),
    )
    ```

2.  **Sealed/Abstract Classes for Distinct States:** Useful for clean state updates and isolating data associated with each state. Suitable when preserving previous data isn't needed or when each state has distinct properties.

    **Example (using sealed classes):**

    ```dart
    sealed class ProfileState {}

    class ProfileLoading extends ProfileState {}

    class ProfileSuccess extends ProfileState {
      ProfileSuccess(this.profile);
      final Profile profile;
    }

    class ProfileFailure extends ProfileState {
      ProfileFailure(this.errorMessage);
      final String errorMessage;
    }
    ```

    **UI Consumption (using `BlocBuilder` and switch statements):**

    ```dart
    BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return switch (state) {
          ProfileLoading() => const CircularProgressIndicator(),
          ProfileSuccess success => ProfileView(success.profile),
          ProfileFailure(errorMessage: final message) => Text(message),
        };
      },
    )
    ```

- **Sharing properties:**  For sealed/abstract classes, share properties by defining them in the parent class or using a common base class.

Choose the approach that best suits the specific use case and data handling requirements.

## Record Types

- Dart 3.0 introduced record types, which allow storing multiple related values without creating a separate data class.
- When using record types, always name positional values for clarity and maintainability.

**Example:**

```dart
// Bad ❗️
Future<(String, String)> getUserNameAndEmail() async => _someApiFetchMethod();

final userData = await getUserNameAndEmail();

if (userData.$1.isValid) {
  // ...
}

// Good ✅
Future<(String, String)> getUserNameAndEmail() async => _someApiFetchMethod();

final (username, email) = await getUserNameAndEmail();

if (email.isValid) {
  // ...
}
```
- Use dedicated data models instead of record types for complex scenarios or when values are used across multiple files.

## Repository Pattern

-   The `HtHeadlinesRepository` acts as an abstraction layer between the data source ( `HtInMemoryHeadlinesClient`) and the BLoCs.
-   This pattern decouples the data fetching logic from the UI and business logic, making the code more modular and testable.

## Dependency Injection

-   `main_*.dart` files suggest a form of manual dependency injection. The headlines client is created and passed into the repository, which is then passed into the App.  This is often used to provide repositories to BLoCs.

## Directory Structure
- The `lib/` directory is organized by feature:
    - `app/`: Contains the main application widget and app-level BLoCs.
    - `headlines-feed/`: Contains the core feature for displaying headlines.
    - `l10n/`: Localization files.
    - `router/`: Navigation and routing logic.
    - `shared/`: Reusable widgets or utilities.

## Page/View Pattern

Each feature typically has a "page" widget and a "view" widget. This promotes separation of concerns, testability, and maintainability.

-   **Page Widget** (e.g., `HeadlinesFeedPage`): A `StatelessWidget` responsible for:
    -   Providing necessary BLoCs and repositories using `BlocProvider` or `MultiBlocProvider`.
    -   Adding initial events to the BLoC (e.g., fetching initial data).
    -   Defining the route for the page.
    -   Gathering dependencies from the context (e.g., using `context.read`).
    -   Providing these dependencies to the `View` (typically via a `BlocProvider`).

-   **View Widget** (e.g., `_HeadlinesFeedView`): A `StatelessWidget` responsible for:
    -   Building the UI based on the current state of the BLoC.
    -   Handling user interactions and dispatching events to the BLoC.
    -   Receiving dependencies from the `Page`.

**Example:**

```dart
// headlines_feed_page.dart
class HeadlinesFeedPage extends StatelessWidget {
  const HeadlinesFeedPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HeadlinesFeedPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HeadlinesFeedBloc(
        headlinesRepository: context.read<HtHeadlinesRepository>(),
      )..add(HeadlinesFeedRequested()),
      child: const _HeadlinesFeedView(),
    );
  }
}

// headlines_feed_view.dart
class _HeadlinesFeedView extends StatelessWidget {
  const _HeadlinesFeedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Headlines')),
      body: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
        builder: (context, state) {
          // ... build UI based on state ...
        },
      ),
    );
  }
}

```
The `View` constructor should be annotated with `@visibleForTesting` to prevent its direct use outside of the `Page`.

## Use Standalone Widgets over Helper Methods

When a widget's build method becomes complex, always prefer creating new standalone widgets instead of helper methods that return widgets.

-   **Benefits:**
    -   **Testability:** Each widget can be tested independently.
    -   **Maintainability:** Smaller widgets are easier to understand and maintain.
    -   **Reusability:** Widgets can be easily reused.
    -   **Performance:** Avoid unnecessary rebuilds of the entire parent widget.

-   Refer to the Flutter team's video: [Splitting widgets to methods is a performance anti-pattern](https://www.youtube.com/watch?v=IOyq-eTRhvo&pp=ygUjc3BsaXR0aW5nIHdpZGdldHMgdG8gbWV0aG9kcyBpcyBhIA%3D%3D)

## Error Handling

Proper error handling is crucial. Follow these practices:

-   **Document Exceptions:** Document exceptions in function documentation comments.
-   **Define Descriptive Exceptions:** Implement `Exception` with descriptive names.
-   **Document No-Operations (No-Ops):** If a function intentionally does nothing, document it with a comment.
- **Handle Errors in Different Layers:**
  - **Data Layer:** Use `try-catch` blocks when interacting with external sources (APIs, databases, etc.).  Throw custom exceptions with descriptive messages.
  ```dart
  // Example (Data Layer)
    Future<List<Headline>> fetchHeadlines() async {
    try {
      final response = await _httpClient.get('/headlines');
      // ... process response ...
      return headlines;
    } catch (e) {
      throw FetchHeadlinesException('Failed to fetch headlines: $e');
    }
  }
  ```
  - **Repository Layer:** Catch exceptions from the Data Layer and either handle them (e.g., retry, return cached data) or re-throw them with more context.
  ```dart
    // Example (Repository Layer)
  Future<List<Headline>> getHeadlines() async {
    try {
      return await _headlinesClient.fetchHeadlines();
    } on FetchHeadlinesException catch (e) {
      // Log the error, potentially retry, or return cached data
      _logger.severe('Error fetching headlines: $e');
      // Optionally re-throw with more context:
      throw GetHeadlinesException('Failed to get headlines: ${e.message}');
    }
  }
  ```
  - **Business Logic Layer (BLoC):** Handle errors from the Repository Layer and emit appropriate states to the UI.
  ```dart
  //Example (BLoC)
  Future<void> _onHeadlinesRequested(
      HeadlinesRequested event,
      Emitter<HeadlinesState> emit,
    ) async {
    emit(HeadlinesLoading());
    try {
      final headlines = await _headlinesRepository.getHeadlines();
      emit(HeadlinesLoaded(headlines));
    } on GetHeadlinesException catch (e) {
      emit(HeadlinesFailure(e.message));
    }
  }
  ```
  - **Presentation Layer:** Display user-friendly error messages based on the states emitted by the BLoC.

## Routing

- The `go_router` package is used for declarative routing and navigation.
- Routes should be structured with sub-routes for logical organization and proper back navigation (e.g., `/flutter/news` instead of `/flutter-news`).
- Use type-safe routes to avoid typos and ensure correct parameter types.
- Prefer `go` over `push` methods for navigation, except when expecting data from a popped route (e.g., a dialog).
- Use hyphens to separate words in URLs (e.g., `/user/update-address`).
- Prefer navigating by name over path to avoid issues if route paths change.
- Use GoRouter's extension methods on `BuildContext` (e.g., `context.goNamed('routeName')`).
- Use path parameters for identifying resources (e.g., `/article/:id`).
- Use query parameters for filtering or sorting resources (e.g., `/articles?date=2024-03-15&category=flutter`).
- Avoid using the `extra` parameter for passing data during navigation, as it doesn't work with deep linking or web.
- Use redirects for scenarios like restricting access based on authentication status.

## Testing

- Strive for 100% test coverage.
- Organize test files to mirror the project structure (e.g., `test/models/model_a_test.dart` for `lib/models/model_a.dart`).
- Assert test results using `expect` or `verify`.
- Use matchers with expectations (e.g., `expect(value, equals(expectedValue))`).
- Use string expressions for types in test descriptions (e.g., `testWidgets('renders $MyWidget', ...)`, but `group(MyWidget, ...)`).
- Write descriptive test names (e.g., `test('given an input, returns the expected output')`).
- Test one scenario per test.
- Prefer finding widgets by type instead of keys (e.g., `find.byType(MyWidget)`).
- Use private mocks (e.g., `class _MockMyClass extends Mock implements MyClass {}`).
- Split tests into groups (e.g., by widget, event, or method).
- Keep test setup (`setUp`, `setUpAll`) inside groups.
- Initialize shared mutable objects per test (within `setUp`).
- Use constants for test tags instead of magic strings.
- Do not share state between tests.
- Use random test ordering (`flutter test --test-randomize-ordering-seed random`).

## Theming

- Use `ThemeData` to define the visual properties of the app (colors, typography, etc.).
- Avoid conditional logic for theming; use `Theme.of(context)` to access theme values.
- For typography:
    - Import fonts and declare them in `pubspec.yaml`.
    - Use `flutter_gen` for type-safe font access.
    - Create custom text styles (e.g., `AppTextStyle`).
    - Use `TextTheme` to apply text styles consistently.
- For colors:
    - Create custom colors (e.g., `AppColors`).
    - Use `ColorScheme` to define component colors.
- Use component themes (e.g., `FilledButtonThemeData`) for widget-specific customization.
- Define spacing constants (e.g., `AppSpacing`) for consistent spacing throughout the UI.

## Layouts

- Flutter layouts are based on constraints that flow down from parent to child widgets.
- Understand the golden rule: "Constraints go down. Sizes go up. Parent sets position."

### Rows and Columns

- Use `Row` and `Column` to lay out widgets horizontally and vertically, respectively.
- `MainAxisSize` (`min`, `max`): Determines how much space the `Row`/`Column` occupies along its main axis.
- `MainAxisAlignment` (`start`, `end`, `center`, `spaceAround`, `spaceBetween`, `spaceEvenly`): Controls how children are positioned along the main axis when there's extra space.
- `CrossAxisAlignment` (`start`, `end`, `center`, `stretch`): Controls how children are positioned along the cross axis.

### Expanded, Flexible, and Spacer

- Use `Expanded`, `Flexible`, and `Spacer` within `Row` and `Column` to control how children share available space.
- `Expanded`: Child expands to fill available space.
- `Spacer`: Creates an empty space that fills available space.
- `Flexible`: Similar to `Expanded`, but allows specifying whether to fill the space (`FlexFit.tight`) or not (`FlexFit.loose`).
- `flex` factor: Determines the relative size of widgets within a `Row` or `Column`.

### Wrap and ListView

- Use `Wrap` to create a layout that wraps its children to the next line/column when they overflow.
- Use `ListView` to create a scrollable list of widgets.
- `scrollDirection`: Specifies the scrolling direction (horizontal or vertical).
- `shrinkWrap`: If `true`, the `ListView` takes up only the space needed by its children in the main axis.

- Use `SingleChildScrollView` to make a single widget scrollable. Prefer `ListView` for lists of children.

### Nesting

- Rows and columns can be nested.
- Be mindful of constraints when nesting, especially with scrollable widgets and `Expanded`.
- Avoid using `Expanded` inside `Wrap`, `ListView`, and `SingleChildScrollView` unless the nested widget has a fixed size.
