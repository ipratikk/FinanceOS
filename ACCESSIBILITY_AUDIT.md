# Accessibility Audit & QA Checklist

## Phase 5 Production Polish

### Hit Targets (44×44 minimum)
- [x] All buttons: 44×44 minimum with `.frame(minWidth: 44, minHeight: 44)`
- [x] Icon buttons: Use `.contentShape(Rectangle())` for full-width clickability
- [x] CardsView: 8 buttons fixed
- [x] AccountsView: 8 buttons fixed
- [x] BanksView: 3 buttons fixed
- [x] CardEditView: 2 buttons fixed
- [x] BankEditView: 2 buttons fixed
- [x] SidebarView: Import button verified

### Full-Width Interactive Areas
- [x] Card rows: Full-width tap target via `.contentShape(Rectangle())`
- [x] Transaction rows: Full-width tap target
- [x] List items: Full-row clickable containers
- [x] Navigation items: Full-row selection

### Accessibility Labels & Hints
- [ ] All icon buttons: Add `.accessibilityLabel()` describing purpose
- [ ] Cards: Add `.accessibilityElement()` with complete context
- [ ] Accounts: Explain account type + balance in accessibility
- [ ] Transactions: Amount + direction accessible via labels
- [ ] Buttons: Clear action descriptions (not just "Edit")

### Focus Management
- [ ] Tab order logical across views
- [ ] Modal sheets: Focus trapped inside sheet
- [ ] Dismiss buttons: Clearly labeled
- [ ] Form navigation: Logical field-to-field progression

### Color & Contrast
- [ ] Text: Minimum 4.5:1 contrast (normal text)
- [ ] Text Large: Minimum 3:1 contrast (18pt+)
- [ ] Icons: Ensure color isn't only differentiator
- [ ] Debit/Credit: Not red/green alone (icon + label required)

### Dynamic Type Support
- [ ] Text scales with system size
- [ ] Layout adjusts at large sizes (no truncation)
- [ ] Minimum 44pt hit targets maintained
- [ ] Line height adjusts automatically

### Localization & RTL
- [ ] All UI strings use String Catalogs (Localizable.xcstrings)
- [ ] No hardcoded text in views
- [ ] Locale-safe number/date formatting via FormatterCache
- [ ] RTL layouts tested: HStack → Frame with .leading alignment
- [ ] Icon direction: Mirror icons in RTL via `.rtlMirror()`

### VoiceOver Testing
- [ ] App launches and navigates with Voice​Over on
- [ ] Text is announced correctly
- [ ] Button purposes are clear
- [ ] Modal dialogs announced as modals
- [ ] Empty states described properly
- [ ] Loading states described ("Loading transactions...")
- [ ] No redundant announcements (e.g., avoid "Button, Edit Card" when label says "Edit")

### Motor Control
- [ ] All tappable targets: Minimum 44×44 points
- [ ] Spacing between targets: Sufficient (8pt min)
- [ ] No accidental taps due to proximity
- [ ] Confirmations for destructive actions (delete)

### Performance & Battery
- [ ] ImageCache active: No repeated AsyncImage allocations
- [ ] FormatterCache active: No repeated NumberFormatter/DateFormatter creation
- [ ] Memoization active: No O(n²) recomputations
- [ ] Remove unneeded `.task` blocks
- [ ] Lazy loading for long lists

### Error States & Recovery
- [ ] Error messages clear & actionable
- [ ] FDSErrorState used consistently
- [ ] Retry options visible
- [ ] Loading states prevent double-submit

### Production Polish
- [ ] No print() statements (use FinanceLogger)
- [ ] No force unwraps (!) in views
- [ ] No AnyView misuse
- [ ] All modifiers use AppTypography, AppSpacing, AppColors
- [ ] No hardcoded sizes/colors/spacing
- [ ] Animations use AppAnimation constants
- [ ] Shadows use AppShadows tokens

### Testing Checklist
- [ ] Manual accessibility scan on iOS/macOS
- [ ] VoiceOver: Swipe navigation, rotor, direct touch
- [ ] Switch Control: Single switch navigation
- [ ] Spoken Content: Read screen enabled
- [ ] Display: High contrast, reduce motion
- [ ] Font: Larger sizes, bold text
- [ ] RTL languages (if supported): Hebrew, Arabic layouts

### Sign-Off
- [ ] All 44×44 hit targets verified ✓
- [ ] All accessibility labels added
- [ ] All focus order logical
- [ ] All contrast ratios meet WCAG AA
- [ ] VoiceOver tested on device
- [ ] RTL tested (if supported)
- [ ] Performance baseline established
- [ ] Production deployment ready
