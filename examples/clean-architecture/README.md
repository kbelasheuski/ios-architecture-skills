# Clean Architecture (Layered) — Example

`UserList` + `UserDetail` split across Domain (entities, use cases, repo protocol), Data (concrete repo + DTOs), Presentation (MVVM with `@Observable`). DI container at composition root.

## Layout

```
Sources/
  App/
    UsersApp.swift
    DIContainer/
      AppDIContainer.swift
      UsersSceneDIContainer.swift
  Domain/
    Entities/User.swift                       (shared)
    Interfaces/UserRepository.swift           (shared)
    UseCases/FetchUsersUseCase.swift
    UseCases/FetchUserUseCase.swift
    UseCases/UpdateUserUseCase.swift
  Data/
    LiveUserRepository.swift                  (shared, plays Data layer)
  Presentation/
    UsersScene/
      Flows/UsersFlowCoordinator.swift
      UserList/
        UserListViewModel.swift
        UserListView.swift
      UserDetail/
        UserDetailViewModel.swift
        UserDetailView.swift
Tests/
  FetchUsersUseCaseTests.swift
  UserListViewModelTests.swift
  UserDetailViewModelTests.swift
  Support/
```

## Real-world refs

- kudoleh/iOS-Clean-Architecture-MVVM — https://github.com/kudoleh/iOS-Clean-Architecture-MVVM
- nalexn/clean-architecture-swiftui — https://github.com/nalexn/clean-architecture-swiftui
- Alexey Naumov, *Clean Architecture for SwiftUI* — https://nalexn.github.io/clean-architecture-swiftui/
- Uncle Bob, *The Clean Architecture* — https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html

## How testing works

Domain layer is pure Swift — Use Cases tested by injecting `FakeUserRepository` directly. Presentation ViewModels tested by injecting Use Case protocols (or live use cases over `FakeUserRepository`). No simulator required.
