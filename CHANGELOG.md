# Change Log

## [version 1.17.03] 2026-04-09

### Updated

- **Rendering Engine**: Enabled Impeller rendering engine
- **CSV Import**: Improved CSV file import handling
- **Logging**: Adopted shared logger across the application
- **Code Organization**: Major refactoring of folder structure and file naming conventions; removed legacy providers folder
- **Code Quality**: Applied `avoid_void_async` lint rule and updated package dependencies

## [version 1.17.02] 2026-04-01

### Updated

- fix Android build
- fCheck 100% score
- **CI/CD Runtime Compatibility**: Updated GitHub Actions workflow dependencies to current action majors compatible with Node.js 24 transition requirements
- **JavaScript Action Runtime**: Configured workflow environment to force JavaScript actions to run on Node.js 24 to avoid upcoming Node.js 20 deprecation warnings
- **Build Tooling Baseline**: Standardized CI Node.js setup to use current runtime for consistent pipeline execution across runners

## [version 1.17.01] 2026-03-08

### Updated

- **State Management**: Removed the legacy state-management package and migrated the app to Flutter's built-in state management primitives (`ChangeNotifier`, `ValueNotifier`, `ListenableBuilder`, and `Navigator`)
- **Navigation and Startup Flow**: Reworked app routing to use the root `Navigator` key and added safer startup synchronization for widget and integration tests
- **Controller Wiring**: Replaced the remaining service-locator and reactive patterns with standard Flutter controller singletons and listenables
- **Tests and Runtime Stability**: Fixed build-time notification issues that surfaced after the migration to Flutter's built-in state flow

## [version 1.17.00] 2026-03-06

### Added

- **Android Support**: Added back Android platform support and project configuration
- **Broader Localization Coverage**: Localized additional app bar actions, tooltips, and list action labels across the UI

### Updated

- **File and Settings Menus**: Replaced remaining inline English labels with localized strings for file operations, settings, zoom, install, and about actions
- **Action Tooltips**: Localized merge, add, edit, delete, copy, snackbar severity, and related helper text
- **Web Focus Behavior**: Improved startup and list focus handling on web to avoid premature focus capture and keep selection behavior consistent

## [version 1.16.02] 2026-03-03

### Added

- **About Page**: New menu entry in Settings popup for app version and license information
- **Version Information**: Displays current app version, build number, and package name
- **License Viewer**: Integration with Flutter's standard license page for all dependencies
- **Localization Support**: About page supports English, French, and Spanish

### Updated

- **GitHub Artifacts**: Enhanced workflow with automatic release creation and artifact management
- **Storage Management**: Implemented conservative cleanup strategy (keep latest 2 releases, 2 artifacts per platform, 10 workflow runs)
- **Quantity-Based Control**: Replaced time-based retention with precise quantity limits for predictable storage
- **Code Quality**: Fixed all magic numbers with semantic constants
- **Dependencies**: Added package_info_plus for version detection

### Infrastructure

- **GitHub Actions**: Enhanced builds.yml with automatic cleanup and release management
- **Documentation**: Updated GitHub artifacts automation documentation
- **Constants**: Added semantic constants for HTTP status, platform spacing, and loading padding

## [version 1.16.01] 2026-02-27

### Update

- fCheck 1.0.2 score 100%
- Update to Flutter 3.41.0 and Dart 3.11.0

## [version 1.16.00] 2026-02-25

### Added

- Localization EN|FR|ES

### Refactor code

## [version 1.15.01] 2026-02-09

### Update

- Maintenance release focused on dead-code cleanup.
- Remove unused-variable warnings while keeping callback/interface parameter intent explicit.
- Improve code quality checks by aligning analyzer and fcheck outcomes.

## [version 1.15.00] 2025-12-27

### Update

- Flutter and Dart version updates to latest (3.38.0)
- Update to sqlite3 ^3.0.0
- Remove legacy snackbar package dependency
- Update builds.yml for CI/CD improvements

### Add

- Add test for ViewAI with 80% code coverage
- Use GLAD to generate Graph.svg

## [version 1.14.00] 2025-10-28

### Update

- Rebrand "MyMoney" to "fMoney" to communicated flutter/free open source

## [version 1.13.04] 2025-10-16

### Add

- TEXTify version 0.4.7
- AI View with Ollama integration for chat and assistant functionality
- CSV importer feature
- Better Keyboard Shortcut system
- SplitResizer for the bottom panel
- MySvg widget for SVG rendering
- Chat history management and Markdown support in AI View

### Update

- Flutter and Dart version updates to latest
- Extensive refactoring of AI-related widgets and services
- Improved keyboard shortcut handling
- Refactored SidePanel to StatefulWidget
- Simplified dual key helper for shortcuts
- Upgraded various packages
- Improved splitter design and package updates
- Enhanced footer functionality with balance calculations
- Renamed folder from tools to tool
- Various UI improvements and theme font scaling

### Fix

- Fixed null value check in footer
- Fixed iOS configuration issues
- Fixed deprecated API code
- Fixed pubspec.yaml for assets/images/platforms/
- Fixed working indicator radius
- Fixed URL for desktop download
- Fixed desktop download names and naming patterns
- Various small improvements and bug fixes

## [version 1.12.00] 2025-03-19

### Add

- Splitter Resizer for the bottom Panel

## Update

- use the latest TEXTify
  
## [version 1.11.07] 2025-01-21

### Update

- Budget feature support small devices

## [version 1.11.06] 2025-01-15

### Add

- Include Incomes categories in Budget View
  
## [version 1.11.05] 2025-01-09

### Update

- Improve the Budget list display

## [version 1.11.04] 2024-12-30

### Add

- Budget View editing Category & jump to category view
- Editing of InvestmentTradeType
- Average Cost of Shares

## [version 1.11.03] 2024-12-29

### Add

- Add Manual Investment transaction can now pick a Category
- Enable editing of Investment-UnitPrice

## [version 1.11.02] 2024-12-28

### Add

- Manual Import Investment Transaction

## [version 1.11.01] 2024-12-27

### Update

- Jump from Investment-SidePanel transactions to StockView
- Editing of Stock Units

## [version 1.11.00] 2024-12-26

### Update

- Fix sorting Category in Transaction View

### Add

- Automatically detect input currency in Bulk-Import
- Display Category distribution graph on Transaction view Side panel

## [version 1.10.04] 2024-12-17

### Add

- Trend chart jump tp Transaction view for the year tapped on the BarChart
- Trend chart tooltips
  
## [version 1.10.03] 2024-12-16

### Add

- Trend chart
  
## [version 1.10.02] 2024-12-12

### Update

- Update to Flutter 3.27.0 and Dart 3.6.0

## [version 1.10.01] 2024-12-08

### Add

- Toggle Category RecurringExpense from the Cashflow views
- A basic budget view of Recurring Expenses
  
### Fix

- Editing of Category Type "Recurring Expense"

## [version 1.10.00] 2024-12-01

### Add

- Chart to Events

## [version 1.9.06] 2024-11-26

### Update

- You can now see the Splits from the Transaction Dialog
- Dialog fields are cleaner

## [version 1.9.05] 2024-11-20

### Add

- Scroll jump to top or bottom

## [version 1.9.04] 2024-11-12

### Fix

- Improve Test for saving and loading from Sqlite

## [version 1.9.03] 2024-11-06

### Added

- Ability to Copy BarChart values to clipboard
- SidePanel BarChart with scale [Daily, Weekly, Monthly, Yearly] used in Categories and Payees

## [version 1.9.02] 2024-11-02

### Added

- New Navigation button to jump to Top and Bottom of list

### Fix

- Repaint transaction list view on Data changes like inline Category Approval

## [version 1.9.01] 2024-10-26

### Added

- Sqlite3 loading in Web Client

## [version 1.9.00] 2024-10-20

### Added

- PREVIEW: Events, no data is persisted. Use in Demo Data.
  
## [version 1.8.54] 2024-08-10

### Added

- Integration test with 50% code-coverage
  
## [version 1.8.53] 2024-08-07

### Added

- NetWorth chart - display major events
  
## [version 1.8.52] 2024-08-04

### Added

- Fix keyboard handling of list view navigation Home/End Up/Down keys
  
## [version 1.8.51] 2024-08-01

### Added

- Lists are now 'adaptive' they will enable horizontal scrolling if the devices are not "large enough".
  
## [version 1.8.50] 2024-07-31

### Update

- User can now set missing Transaction:Category directly from any Transaction List
- Rebuild the Demo data

## [version 1.8.49] 2024-07-29

### Added

- ViewAccount:Detail - show Distribution of Cash and Investment
  
## [version 1.8.48] 2024-07-24

### Added

- Multiple Column Filtering
  
## [version 1.8.47] 2024-07-23

### Added

- Jump from AccountView to InvestmentView
- StockView:Chart Display Dividends
  
## [version 1.8.46] 2024-07-22

### Updated

- StockView: new column for Dividend
- StockView:Details panel: Display Splits and Dividend panels
- Add DateRange column to Stock view
  
## [version 1.8.45] 2024-07-21

### Updated

- Use Yahoo-V8 backend to download the StockSplits data

## [version 1.8.44] 2024-07-19

### Added

- Download and display StockSplits
- Display FieldQuantity in Blue for positive and Orange for negative
- Improve FieldQuantity to show + sign on positive numbers

## [version 1.8.43] 2024-07-18

### Added

- Stock view:InfoPanel add JumpTo [Accounts | Transactions]
  
## [version 1.8.43] 2024-07-17

### Added

- Stock view now has Pivot for Toggles on holding: [Close | Active | All ]

## [version 1.8.43] 2024-07-15

### Added

- Display purchase and sale activity on the stock line chart
- Footer for Average of MoneyAmount or Quantity, with tooltips
  
## [version 1.8.42] 2024-07-13

### Update

- StockChart now has a way to refresh fetching the price history
- Add tooltips to Stock and Network LineCharts

## [version 1.8.41] 2024-07-12

### Update

- Line Chart now renders in Green or Red base on value outcome of first and last values
  
## [version 1.8.40] 2024-07-09

### Added

- New column [Paid On] to help with Credit Card statement

## [version 1.8.39] 2024-07-06

### Added

- Import text: Ability to toggle Credit/Debit the input amounts
  
## [version 1.8.38] 2024-07-05

### Added

- Use OCR for Import from text, tested on macOS using Tesseract-OCR
  
## [version 1.8.37] 2024-07-04

### Added

- Search Payee name using Google Web Search
- Jump from Info:Transaction list to first Matching counter Transaction
  
## [version 1.8.36] 2024-07-03

### Updated

- Improve UX for Range Years selector
  
## [version 1.8.35] 2024-06-28

### Added

- Toggle Transaction Status ['_','C','E','R','V']
- NetWorth chart
  
## [version 1.8.34] 2024-06-27

### Added

- Category suggestion [Approval|Reject]
  
## [version 1.8.33] 2024-06-26

### Updated

- Use Markdown in [Policy page]
- Show a [Clear Filters] on empty list
  
## [version 1.8.32] 2024-06-25

### Added

- Move Rental checkbox to Settings page

## [version 1.8.31] 2024-06-24

### Added

- General Setting is now a Page instead of a dialog
- Policies is now a Page
- Switched state management to Flutter's built-in controllers and listeners

## [version 1.8.30] 2024-06-20

### Added

- load zip [.mmcsv] file from WebClient
- Save and Load Zip .mmcsv file
- MRU - Select previous loaded files directly from the title
  
## [version 1.8.29] 2024-06-19

### Added

- Improve [Import by Text Panel], now showing Duplicated/Skipped entries

## [version 1.8.28] 2024-06-18

### Added

- Improve UX for QFX file import
  
## [version 1.8.27] 2024-06-17

### Added

- You can now merge Payee from Transaction Edit dialog
- Auto Footer-Tally on the InfoPanel-List
- Long Press on InfoPanel of Loans to show the Detail dialog
  
## [version 1.8.26] 2024-06-16

### Added

- List View Footer
- NetWorth reveal button on the Application bar

## [version 1.8.25] 2024-06-14

### Added

- Editing of Rental Building Land & Property evaluation

## [version 1.8.24] 2024-06-13

### Added

- New Import Transaction Wizard

## [version 1.8.23] 2024-06-12

### Added

- Category View now has a [Rollup Sum] column
  
## [version 1.8.22] 2024-06-11

### Added

- UI to add a new Category

## [version 1.8.21] 2024-06-10

### Added

- New [clear all filters] button in the header

## [version 1.8.20] 2024-06-09

### Updated

- Move Import to main menu
- Pending Changes dialog can now [Save to SQL] [Save to CSV]

### Added

- Main Menu

## [version 1.8.19] 2024-06-08

### Updated

- Loans: Display list of transactions

## [version 1.8.18] 2024-06-05

### Added

- Persist Column filters
  
## [version 1.8.17] 2024-06-04

### Fixed

- use package [sqlite3_flutter_libs] for Windows
  
### Updated

- Filter by Column

## [version 1.8.16] 2024-0-03

### Added

- WIP: Jump from Transaction to view for Accounts, Categories, or Payees

### Updated

- Show a filter-icon if a column is using filtering
- Performance: using CompareIgnoreCase2

### Fixed

- Transaction view: Sorting by currency

## [version 1.8.16] 2024-06-02

### Added

- Payee Merge can now choose the category to use
- Payee View: new column for Categories
  
## [version 1.8.14] 2024-05-28

### Added

- Copy CSV to clipboard for Main List and Info Panel
  
## [version 1.8.13] 2024-05-27

### Added

- Account new column [Updated], show the last time the account was edited

## [version 1.8.12] 2024-05-26

### Added

- Privacy Policy
- Licenses

## [version 1.8.11] 2024-05-24

### Added

- Android Beta Test deploy

## [version 1.8.10] 2024-05-21

### Updated

- Scroll into view the newly added Account and Category

## [version 1.8.9] 2024-05-19

### Added

- Add Category UX
- Feature for Merging|Appending categories

## [version 1.8.8] 2024-05-18

### Added

- Category Color indicate the override colors
- Color Picker

## [version 1.8.7] 2024-05-16

### Added

- Bulk Delete for Transactions
- Category list now has a column for [Level]

### Updated

- Moved the Edit & Delete buttons to the View-Header
- Multi-Editing support for Transaction:Payee
- Timeline chart is now also a heatmap

## [version 1.8.6] 2024-05-15

### Updated

- Flutter 3.22.0 & Dart 3.4.0

### Added

- Multi-Editing support for Transactions:Category

## [version 1.8.5] 2024-05-13

### Added

- Multiple selection

## [version 1.8.4] 2024-05-10

### Added

- UX Merge Payees

## [version 1.8.3] 2024-05-08

### Updated

- Adaptive Recurring Payment Card now using Wrap

## [version 1.8.2] 2024-05-07

### Updated

- Improve recurring card UI
- Improve CashFlow layout

## [version 1.8.1] 2024-05-06

### Updated

- Improve TimeLine-range-slider

## [version 1.8.0] 2024-05-02

### Updated

- Detail panel now offers Edit, Delete, Copy actions

## [version 1.7.9] 2024-04-15

### Added

- Recurring Transactions

## [version 1.7.8] 2024-04-14

### Updated

- Stock view: new column for Profit per Security

### Added

- QuantifyWidget
- Copy Info-transactions to the clipboard on views [Account, Stock & Rental]
- Money_Widget (display negative value in Red, positive in Green)

## [version 1.7.7] 2024-04-12

### Added

- Running balance on Investment-Stocks view

## [version 1.7.6] 2024-04-12

### Added

- Investment transactions pert Stock (Security)

## [version 1.7.5] 2024-04-09

### Added

- Rental P&L cards

### Updated

- Show Split transactions on the Transaction View detail panel
- Rental view shows Currency of the associated account linked by the Income Category

## [version 1.7.4] 2024-04-05

### Added

- Show last modified date of opened file
- Show currency column in Transaction view

### Updated

- Improve bottom legend for stock chart
- Custom Filter of column by currency

## [version 1.7.3] 2024-04-04

- Upgrade packages: [file_picker: 8.0.0+1], [sqlite3: 2.4.2], [dart_pdf_reader: ^1.0.0]
- Better Sorting fallback
- Set API Key directly from the Stock Chart

## [version 1.7.2] 2024-04-03

### Added

- Download stock history from [twelvedata.com]

## [version 1.7.1] 2024-04-02

### Added

- Stock view
- Work in progress = Investment transactions

## [version 1.7.0] 2024-04-01

- Major refactor, simplify by reducing Template ```Field<C,T>``` to ```Field<T>```
- Long Press on Chart Bars will copy the tooltip text to the clipboard

## [version 1.6.3] 2024-03-31

### Changed

- Detail panel is now displaying the ReadOnly object fields

### Updated

- Update package [file_picker: 8.0.0]
- Update package [fl_chart: ^0.67.0]

## [version 1.6.2] 2024-03-30

### Updated

- Reach MVP for the Text Import feature

## [version 1.6.1] 2024-03-29

### Updated

- List selection is now using Unique Id instead of Index

### Fixed

- Chart reverse order

## [version 1.6.0] 2024-03-28

### Added

- Transfers View

## [version 1.5.1] 2024-03-26

### Updated

- Improve the Delete confirmation dialog

## [version 1.5.0] 2024-03-25

### Added

- Account chart of Max Balances per years

### Fixed

= When loading via json.getInt() we now default to -1 for entity ID, since Zero is a valid ID

## [version 1.4.9] 2024-03-24

### Added

- Dialog showing list of pending changes [Added|Modified|Deleted]

## [version 1.4.8] 2024-03-23

### Added

- Save to new SQL file

### Update

- Display Transfer or Payee Name

## [version 1.4.7] 2024-03-22

### Updated

- Remove unused layoutBuild(constraint)
- Editing of Account [accountId, ofxAccountID, description]

### Added

- User can now Add new Accounts
- Use Flutter's built-in state management
- Load from CSV [mymoney.mmcsv] file
- Close and create a new file

## [version 1.4.6] 2024-03-20

### Added

- PickerForAccountType

### Updated

- Improve ImportQFX

### Refactor

- Rename class MyMoney to MainApp
- Theme.of(context).colorScheme to getColorTheme(context)

## [version 1.4.5] 2024-03-19

## Fixed

- Fix for Table header filter
- Fix Web version

## Added

- Letter Picker

## Updated

- ImportQFX: skip duplicates

## Refactor

- Loading screen, app bar header
- Transaction Payee
- [notifyTransactionChange()| MoneyObject.addEntry()] use named parameters

## [version 1.4.4] 2024-03-18

### Fixed

- Transaction Amount List and Dialog

### Updated

- Improve layout for Large and small screen
- Only show the ADD (+) on the details panel if the Transactions tab is selected and expanded

### Added

- Display Green, Orange, Red adornments to list items
- Script for dependency graph using Lakos and to graphviz

## [version 1.4.3] 2024-03-17

### Updated

- MVP use case: Duplicate & Edit (Date, Payee, Amount) of a transaction
- Mutate Dialog for Transaction : Starts from a ReadOnly view user can then decide
  to [Delete|Duplicate|Edit]

## [version 1.4.2] 2024-03-16

### Updated

- Fields support for Editable vs ReadOnly
- List View
  - Optional Un-Selectable row
  - Refresh when data is mutated
  - Prioritize Selection color before Hover color

## [version 1.4.1] 2024-03-15

### Updated

- TextEditWithPicker now has a filter

## [version 1.4.0] 2024-03-14

### Fixed

- Demo data use negative amount for expenses

### Update

- Column Header are now aligned with content [ L | C | R ]
- SanKey
  - More usable on small devices (phones)
  - Net Lost now displays on the left side of Expenses
  - Width is flush to the view port

## [version 1.3.9] 2024-03-13

### Added

- Add new Transaction from Accounts Detail Panel
- ComboEditBox

### Update

- Remember selection and sorting of details panel for Account view
- Improve View Header, use less space
- Improve mobile support when editing text field
- Only display the segment selection '✓' symbol on larger screen

## [version 1.3.8] 2024-03-11

### Added

- Enable editing the Category of a transaction
- Add filter-text-box to Table Column Filter dialog
- Import via batch text Date-Description-Amount

## [version 1.3.7] 2024-03-04

### Added

- Import transactions using free style text

## [version 1.3.6] 2024-03-03

### Added

- Column Filter for Text type

### Improved

- Import from clipboard
- Select Account when doing a Clipboard Import
- Scrollable content

## [version 1.3.5] 2024-03-01

### Fixed

- Fix CSV Transaction.Amount

### Added

- Import Account transactions via the Clipboard Date,Description,Amount

### Updated

- Flutter 3.19.2

## [version 1.3.4] 2024-02-25

- Layout Multi columns details panel

## [version 1.3.3] 2024-02-24

- Mutation of MoneyObject
- Ability to change Account is Open or Closed

## [version 1.3.2] 2024-02-22

- Currency toggle in Details panel

## [version 1.3.1] 2024-02-21

- Remember Details panel last tab selection
- Improve the delete dialog
- Add Mouse Hover color to list view items
- Delete Transaction from Details Panel

## [version 1.3.0] 2024-02-19

- Improve Sankey layout
- Update most packages
- Fix deprecated keyboard API

## [version 1.2.17] 2024-02-18

- Adaptive menus - show label on left side menu when the screen is larger than 1000 pixels
- Flutter 3.19.0 Dart 3.3.0

## [version 1.2.16] 2024-02-14

- Adjusted - Improve Dialog full screen on small devices (Widget smaller than 600 pixels)

## [version 1.2.15] 2024-02-14

- Improve Dialog full screen on small devices

## [version 1.2.14] 2024-02-11

- Improve List view for mobile

## [version 1.2.08] 2024-02-04

- Ensure Model ID are unique and not -1
- Implement Delete Payee

## [version 1.2.07] 2024-02-03

- fix web version

## [version 1.2.06] 2024-02-02

- Implement SQL "Inserts|Update|Delete"

## [version 1.2.05] 2024-02-01

- Improved Badge for Changes, now showing +Added -Deleted
- Improved Import QFX

## [version 1.2.04] 2024-01-31

- Badge counter show number of changes
- Improve the Delete confirmation Dialog

## [version 1.2.03] 2024-01-30

- Render Amount in any ISO4217 currency
- Normalize balance amount to currency USD
- Demo Data for Aliases
- Add Flags to Currencies & Accounts
- fix the iOS build, min iOS version 13

## [version 1.2.02] 2024-01-29

- Load and Save Currencies

## [version 1.2.01] 2024-01-28

- Better Demo Data
- Refactor onOpen...onSave

## [version 1.2.00] 2024-01-27

- Complete Rental fields
- Text filter on all table views

## [version 1.1.05] 2024-01-26

- All the fields for Transaction

## [version 1.1.04] 2024-01-25

- Add Status column to Transaction Table
- Improve font scaling UX

## [version 1.1.03] 2024-01-23

- Improve Table List column by using adjustable widths

## [version 1.1.02] 2024-01-21

- MyJson helper
- Compact List for Categories

## [version 1.1.01] 2024-01-22

- Adaptive View content (Accounts and Transactions)
- LINT enforce all Functions and Methods must have a return type

## [version 1.1.00] 2024-01-20

- Category list & Details panel show Colors
- Major refactor moved to Self describing Declarative Properties

## [version 1.0.21] 2024-01-17

- Refactor reduce code to deal with all tables
- All 16 tables now have Load & Save implementations, not all fields are implemented

## [version 1.0.20] 2024-01-16

- Refactor saving toCSV

## [version 1.0.19] 2024-01-15

- Detail Panel, Split transaction

## [version 1.0.18] 2024-01-14

- Start basic documentation
- Refactor MoneyObjects

## [version 1.0.17] 2024-01-13

- Field [type.widget] used in CategoryList for Color
- Load all Account,Alias,Category,Payee,Rental,RentUnit SQLite fields
- Add Filter input to ViewTransaction List

## [version 1.0.16] 2024-01-11

- Load data for Transaction.Status
- Refactor use [Field Definition] model

## [version 1.0.15] 2024-01-10

- Basic Save as CSV
- Show OS container folder

## [version 1.0.14] 2024-01-09

- Performance improvement on Transaction list

## [version 1.0.13] 2024-01-08

- UX for Delete from the [DetailsPanel]
- Remember each views list selected item
- Refactor views - use TableTransactions for details panel
- Improve theme color layout

## [version 1.0.12] 2024-01-06

- SegmentControl for DetailsPanel
- Improve Detail panel Tab Selection
- View Aliases - Show transactions for the selected alias

## [version 1.0.11] 2024-01-05

- Persist user sorting preference of all Views
- User choice "Include Closed Accounts"
- Fix the execution of tests

## [version 1.0.10] 2024-01-04

- Basic QFX import
- View Aliases
- Convert MoneyEntity ID from [num] to [int]

## [version 1.0.9] 2024-01-01

- Improve Table performance
- Refactor Transaction Table view

## [version 1.0.8] 2023-12-31

- Improve performance of Table View Row selection

## [version 1.0.7] 2023-12-30

- Detail Transactions for Payees and Categories
- Center & scrollable left menu bar
- Improve Chart tooltips
- Migrate to sqlite3 & sqlite3_flutter_libs

## [version 1.0.6] 2023-12-29

- Migrate to FL_CHART
- Refactor to use strong typed everywhere

## [version 1.0.5] 2023-10-28

- ViewCategories - filter by types
- Double Click to open Details Panel
- Package path: 1.9.0

## [version 1.0.4] 2023-10-27

- Fix Chart on ViewByAccounts
- Add keyboard binding
- Upgrade to Flutter 3.16.5

## [version 1.0.2] 2023-10-19

- macOS is working again
- Transaction 1 year Chart period

## [version 1.0.1]

- Improve a few area

## [version 1.0.0]

- Initial app
