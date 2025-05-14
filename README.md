# Task Manager - Flutter CRUD App

## Overview
This is a Flutter application that implements a full-stack CRUD (Create, Read, Update, Delete) module for managing tasks. It integrates with a remote API for data persistence, uses Hive for local caching, and follows the BLoC pattern for state management. The app supports offline-first functionality, real-time UI updates, search, sorting, filtering, pagination, and theme switching.

## Setup Instructions
1. **Prerequisites**:
   - Flutter SDK (version 3.0.0 or higher)
   - Dart (version 2.17.0 or higher)
   - An IDE (e.g., VS Code, Android Studio)

2. **Clone the Repository**:
   ```bash
   git clone https://github.com/shramana263/flutter-crud.git
   cd flutter_crud_app
   ```

3. **Install Dependencies**:
   Run the following command to install the required packages:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   Ensure you have an emulator or physical device connected, then run:
   ```bash
   flutter run
   ```

4. **Run the App in web**:
   If you want to run it on web server, then run:
   ```bash
   flutter run -d web-server
   ```

## API Endpoints Documentation
The app uses [JSONPlaceholder](https://jsonplaceholder.typicode.com) as a mock API for task management. The following endpoints are used:

- **GET /todos**: Fetch all tasks.
- **POST /todos**: Create a new task.
- **PUT /todos/{id}**: Update a task by ID.
- **DELETE /todos/{id}**: Delete a task by ID.

**Note**: JSONPlaceholder is a mock API, so updates and deletes are simulated and not persisted.

## Usage Instructions
1. **Launch the App**: Start the app on your device or emulator.
2. **View Tasks**: The home screen displays a list of tasks fetched from the API or local storage.
3. **Add a Task**:
   - Tap the floating action button (+) to open the task form.
   - Enter the task title, description, priority (1-5), and completion status.
   - Tap "Add Task" to save.
4. **Edit a Task**:
   - Tap the edit icon on a task card to open the form pre-filled with the task details.
   - Update the fields and tap "Save Changes".
5. **Delete a Task**:
   - Swipe a task card to the left or tap the delete icon.
   - Confirm the deletion in the dialog.
6. **Search Tasks**:
   - Use the search bar at the top to filter tasks by title or description.
7. **Sort and Filter**:
   - Use the sort menu in the app bar to sort tasks by date, priority, or title (ascending/descending).
8. **Theme Switching**:
   - The app automatically switches between light and dark themes based on your system settings.

## Architecture Overview
The app follows a layered architecture with the BLoC pattern:

- **Data Layer**:
  - `models/task.dart`: Defines the Task model with Hive annotations for local storage.
  - `datasources/local/database_helper.dart`: Manages local storage using Hive.
  - `api/task_api_service.dart`: Handles API requests using the `http` package.
  - `repositories/task_repository.dart`: Abstracts data sources (API and local) and handles offline-first logic.

- **Business Logic Layer**:
  - `bloc/task/task_bloc.dart`: Manages app state and handles events like fetching, adding, updating, and deleting tasks.
  - `bloc/task/task_event.dart`: Defines events for the BLoC.
  - `bloc/task/task_state.dart`: Defines states for the BLoC.

- **Presentation Layer**:
  - `screens/task_list_screen.dart`: Displays the list of tasks with search, sort, filter, and pagination.
  - `screens/task_form_screen.dart`: Provides a form for adding/editing tasks.
  - `widgets/task_card.dart`: Reusable widget for displaying a task.
  - `widgets/search_bar.dart`: Reusable widget for search with debounce.

- **Core**:
  - `di/service_locator.dart`: Sets up dependency injection using `get_it`.
  - `errors/exceptions.dart`: Defines custom exceptions for error handling.
  - `theme/app_theme.dart`: Manages light and dark themes.

## Testing Information
- **Unit Tests**: The project structure supports unit testing, but tests are not implemented. You can add tests in the `test/` directory for the repository, BLoC, and API service.
- **Widget Tests**: Widget tests can be added for `TaskCard` and `SearchBar`.
- **Integration Tests**: Integration tests can be written to simulate user interactions like adding and deleting tasks.

To run tests:
```bash
flutter test
```

## Bonus Features Implemented
- Search functionality with debounce.
- Sorting and filtering options for the task list.
- Offline-first functionality with sync when online.
- Dark/light theme switching.
- Pagination for large datasets.

## Known Limitations
- JSONPlaceholder API does not persist changes, so updates and deletes are simulated.
- Advanced features like WebSocket real-time updates or Firebase integration are not implemented due to the mock API constraint.
