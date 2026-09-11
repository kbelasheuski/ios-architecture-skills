# MVC Example (Apple Cocoa MVC, UIKit)

Reference impl of `UserList` + `UserDetail` using vanilla Cocoa MVC.

## Layout

```
Sources/
  App/
    SceneDelegate.swift                 // composition root
  Domain/
    User.swift                          // shared
    UserRepository.swift                // shared
  Data/
    LiveUserRepository.swift            // shared
  Views/
    UserCell.swift
  Controllers/
    UserListViewController.swift        // load, paginate, navigate
    UserDetailViewController.swift      // fetch, edit, save
Tests/
  UserListViewControllerTests.swift
  UserDetailViewControllerTests.swift
  Support/
    FakeUserRepository.swift            // shared
    Fixtures.swift                      // shared
```

## Real-world refs

- Apple Cocoa MVC docs: https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Model-View-Controller/Model-View-Controller.html
- Apple `UITableViewDiffableDataSource`: https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource

## How testing works

MVC is the **hardest to test**: business state lives on the view controller. Tests load `view`, drive lifecycle, then assert on internal state via test-only hooks or via the table view's row counts.

This example tests by injecting `FakeUserRepository`, calling `_ = sut.view` to trigger `viewDidLoad`, then yielding the runloop until the async load settles. Verifies row count and selection navigation.
