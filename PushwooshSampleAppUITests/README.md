# PushwooshSampleApp UI Tests

Comprehensive UI test suite for the PushwooshSampleApp using XCTest framework and Page Object Model pattern.

## Test Structure

### Test Files

1. **PushwooshSampleAppUITests.swift**
   - Basic UI tests covering all major features
   - Tests for side menu navigation
   - Individual feature tests (Registration, Tags, User, etc.)
   - Performance tests

2. **PushwooshPageObjectTests.swift**
   - Advanced tests using Page Object Model
   - Integration tests
   - Flow tests
   - Performance measurements

### Page Objects

Located in `Pages/` directory:

1. **BaseScreen.swift**
   - Base class for all page objects
   - Common navigation methods
   - Alert handling utilities
   - Input helpers

2. **RegistrationScreen.swift**
   - Push notification registration
   - Toggle notifications
   - Get notification status

3. **TagsScreen.swift**
   - Set tags
   - Load tags
   - Verify tags

4. **UserScreen.swift**
   - Set user ID
   - Set email
   - Clear fields

## Running Tests

### From Xcode

1. Open `PushwooshSampleApp.xcworkspace`
2. Select `PushwooshSampleApp` scheme
3. Press `Cmd+U` to run all tests
4. Or use Test Navigator (Cmd+6) to run individual tests

### From Command Line

```bash
# Build for testing
xcodebuild \
  -workspace PushwooshSampleApp.xcworkspace \
  -scheme PushwooshSampleApp \
  -sdk iphonesimulator \
  build-for-testing

# Run all tests
xcodebuild \
  -workspace PushwooshSampleApp.xcworkspace \
  -scheme PushwooshSampleApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test-without-building

# Run specific test class
xcodebuild \
  -workspace PushwooshSampleApp.xcworkspace \
  -scheme PushwooshSampleApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:PushwooshSampleAppUITests/PushwooshPageObjectTests \
  test-without-building

# Run specific test method
xcodebuild \
  -workspace PushwooshSampleApp.xcworkspace \
  -scheme PushwooshSampleApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:PushwooshSampleAppUITests/PushwooshPageObjectTests/testRegistrationFlow \
  test-without-building
```

## Test Coverage

### Side Menu
- ✅ Open and close menu
- ✅ Navigate between categories
- ✅ Multiple open/close cycles

### Registration
- ✅ View elements verification
- ✅ Toggle push notifications
- ✅ Get notification status
- ✅ Status contains HWID
- ✅ Status contains authorization info

### Tags
- ✅ Set individual tags
- ✅ Set multiple tags
- ✅ Load tags
- ✅ Verify tag persistence
- ✅ Tags after navigation

### User
- ✅ Set user ID
- ✅ Set email
- ✅ Set both user ID and email
- ✅ Clear fields

### Device Info
- ✅ View elements
- ✅ Copy HWID

### Communication
- ✅ View elements
- ✅ Post event

### Integration Tests
- ✅ Complete user registration flow
- ✅ Set tags and verify persistence
- ✅ Navigate through all categories

### Performance
- ✅ App launch performance
- ✅ Menu animation performance
- ✅ Navigation performance

## Best Practices

### Using Page Objects

```swift
func testExample() throws {
    let registrationScreen = RegistrationScreen(app: app)

    // Navigate to screen
    registrationScreen.navigateToCategory("Registration")

    // Verify screen loaded
    registrationScreen.verifyScreenLoaded()

    // Perform actions
    registrationScreen.toggleNotifications()

    // Verify results
    let status = registrationScreen.getNotificationStatus()
    XCTAssertTrue(status.contains("authorized"))
}
```

### Adding New Tests

1. Create a new test method in appropriate test class
2. Use Page Objects for screen interactions
3. Follow naming convention: `test<Feature><Action>()`
4. Add assertions to verify expected behavior
5. Clean up state if needed

### Adding New Page Objects

1. Create new file in `Pages/` directory
2. Inherit from `BaseScreen`
3. Define element getters (private computed properties)
4. Implement action methods (public)
5. Add verification methods
6. Add to project using Ruby script

## Continuous Integration

### GitHub Actions Example

```yaml
name: UI Tests

on:
  pull_request:
    branches: [ master ]

jobs:
  ui-tests:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app

    - name: Build for Testing
      run: |
        xcodebuild \
          -workspace PushwooshSampleApp.xcworkspace \
          -scheme PushwooshSampleApp \
          -sdk iphonesimulator \
          build-for-testing

    - name: Run UI Tests
      run: |
        xcodebuild \
          -workspace PushwooshSampleApp.xcworkspace \
          -scheme PushwooshSampleApp \
          -sdk iphonesimulator \
          -destination 'platform=iOS Simulator,name=iPhone 15' \
          test-without-building
```

## Troubleshooting

### Tests Fail to Launch App

**Issue**: App doesn't launch or crashes immediately

**Solutions**:
- Clean build folder (Cmd+Shift+K)
- Reset simulator (Device > Erase All Content and Settings)
- Rebuild project

### Elements Not Found

**Issue**: `XCTAssertTrue(element.exists)` fails

**Solutions**:
- Verify element exists in UI
- Check accessibility identifiers
- Add wait conditions: `element.waitForExistence(timeout: 5)`
- Use Xcode UI Recording to identify correct element

### Flaky Tests

**Issue**: Tests pass sometimes but fail other times

**Solutions**:
- Add explicit waits: `Thread.sleep(forTimeInterval: 1)`
- Use `waitForExistence` instead of direct assertions
- Verify animations complete before interactions
- Check for race conditions

### Performance Tests Fail

**Issue**: Performance metrics don't meet expectations

**Solutions**:
- Adjust baseline metrics in Xcode
- Run on consistent hardware
- Close other apps during testing
- Use Debug configuration for consistent results

## Contributing

When adding new features to the app:

1. Add corresponding UI tests
2. Use Page Object pattern
3. Update this README
4. Run all tests before committing
5. Ensure tests pass in CI

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
- [Page Object Pattern](https://martinfowler.com/bliki/PageObject.html)
