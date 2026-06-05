# Hungi — Developer Handoff

## What this app does

Hungi is an iOS weekly meal-prep planner. The user walks through a guided onboarding flow each week to specify what ingredients they have and what cuisines they want, then swipes Tinder-style through ranked recipe cards to build a "plate" of meals. The app generates a grocery diff list, lets them tag meals as breakfast/lunch/dinner, and saves everything to a weekly plan.

---

## Tech Stack & Key Dependencies

| What | Details |
|------|---------|
| Language | Swift 5.9 |
| UI | SwiftUI (iOS 17+) |
| Persistence | SwiftData — no external database or networking |
| Image selection | PhotosUI / PhotosPicker |
| Project generation | XcodeGen (`project.yml` → `.xcodeproj`) |
| Minimum target | iOS 17.0 (required for `withAnimation` completion callbacks and `@Observable`) |
| External dependencies | **None.** No Swift Package Manager, no CocoaPods. |

Run `bash generate.sh` from inside `MealPrepMVP/` to regenerate the `.xcodeproj` after adding new `.swift` files. The script installs XcodeGen via Homebrew if needed.

---

## Project Structure

```
MealPrepMVP/
├── App/
│   ├── MealPrepApp.swift          # Entry point, ModelContainer init, seed data, global UIKit appearance
│   └── ContentView.swift          # Root router + MainTabView + DevResetView (DEBUG only)
│
├── Models/                        # Pure SwiftData @Model classes
│   ├── Recipe.swift               # Core recipe: name, mealType, cuisine, rating, macros, imageData
│   ├── RecipeIngredient.swift     # Child of Recipe (cascade delete)
│   ├── PantryItem.swift           # What user has at home; also defines ItemUnit.options
│   ├── GroceryItem.swift          # Shopping list item; isChecked toggle
│   ├── UserProfile.swift          # Just name + createdAt; one record = user exists
│   ├── WeeklyPlan.swift           # Holds [Recipe] + target B/L/D counts + computed totals
│   ├── MealType.swift             # Static constants (breakfast/lunch/dinner/any) + icon/color/displayName
│   └── CuisineType.swift          # 11 cuisine options with emoji; used in flow step 3 and scoring
│
├── Planning/                      # All onboarding/planning wizard code
│   ├── FlowCoordinator.swift      # @Observable wizard state; owns accepted/declined recipes, cuisines, pantry
│   ├── WeeklyPlanningFlow.swift   # Routes Step enum → correct step view
│   ├── WeeklySummaryView.swift    # Final step: assign B/L/D, add/remove meals, save to plan
│   └── Steps/
│       ├── NameEntryStep.swift        # Step 1 (first-time users only): enter name
│       ├── IngredientsEntryStep.swift # Step 2: type key ingredients (HIGH matching weight)
│       ├── MealCountStep.swift        # Step 3: cuisine chip picker (MEDIUM weight) — misnamed, no meal count
│       └── PantrySelectionStep.swift  # Step 4: review/edit pantry items pre-populated from last week
│   └── Swipe/
│       ├── RecipeSwipeView.swift      # Step 5: Tinder cards, scoring algorithm, macros live-total bar
│       ├── RecipeCardView.swift       # Single swipe card: image, badges, match bar, rating
│       └── RecipeDetailCardView.swift # Modal on card tap: full ingredients, macros, "Add to plate"
│
├── Services/
│   ├── MatchingService.swift      # ⚠ UNUSED — matching is done inline in RecipeSwipeView (see note below)
│   └── GroceryDiffService.swift   # Computes (plan ingredients) minus (pantry items) → grocery list
│
└── Views/
    ├── Theme/
    │   ├── HungiTheme.swift       # All colors, typography, button styles, view modifiers
    │   └── PixelComponents.swift  # Reusable components: ParchmentCard, PixelBadge, SwipeStamp, etc.
    ├── WeeklyOverview/
    │   └── WeeklyOverviewView.swift  # Tab 1: current week plan, grouped by meal type, totals at top
    ├── Kitchen/
    │   └── KitchenView.swift         # Tab 2: combined shopping list + pantry; swipe to move items
    ├── Grocery/
    │   └── GroceryListView.swift     # ⚠ ORPHANED — superseded by KitchenView, not in tab bar
    ├── Pantry/
    │   └── PantryView.swift          # ⚠ ORPHANED — superseded by KitchenView, not in tab bar
    └── Recipes/
        ├── RecipeListView.swift      # Tab 3: browse + delete recipes; RecipeRow with rating
        ├── RecipeDetailView.swift    # Full recipe view with 1-10 rating tap buttons
        └── AddEditRecipeView.swift   # Create/edit recipe form (photos, cuisine, macros, ingredients)
```

---

## How the App Flows

### Onboarding / Weekly Planning (shown when no UserProfile OR no WeeklyPlan)

```
ContentView → WeeklyPlanningFlow → FlowCoordinator.step:

  .name          → NameEntryStep          (first launch only; saves UserProfile)
  .ingredients   → IngredientsEntryStep   (type key ingredients; stored in keyIngredients[])
  .mealCount     → MealCountStep          (cuisine chips; stored in selectedCuisines)
  .pantry        → PantrySelectionStep    (pre-populated from last week's PantryItems)
  .swiping       → RecipeSwipeView        (ranked swipe deck; builds acceptedRecipes[])
  .summary       → WeeklySummaryView      (assign B/L/D, remove/add, save to SwiftData)
  .done          → ContentView shows MainTabView
```

Returning users skip `.name` and start at `.ingredients`.

### Main Tabs

```
Tab 1: Overview  — WeeklyOverviewView   (current plan, totals at top)
Tab 2: Kitchen   — KitchenView          (shopping list + pantry combined)
Tab 3: Recipes   — RecipeListView       (full CRUD)
Tab 4: Dev       — DevResetView         (DEBUG builds only)
```

### Scoring Algorithm (RecipeSwipeView.rankedMatches)

```swift
score = min(1.0, baseScore + keyBonus + cuisineBonus)

baseScore    = matched pantry items / total recipe ingredients
keyBonus     = sum(+0.25 for each keyIngredient that appears in any ingredient name)
cuisineBonus = +0.2 if recipe.cuisine is in selectedCuisines (and list is non-empty)
```

---

## What's Working

- Full onboarding flow end-to-end (name → ingredients → cuisine → pantry → swipe → summary → tabs)
- Swipe animations: accept/decline animate the card fully off screen before updating the deck (uses `withAnimation` completion callback, iOS 17 only)
- Recipe card deck: uses `remainingMatches.prefix(3)` — no index tracking, cards cannot "cycle back"
- Live macro totals update on the swipe page as recipes are accepted
- Summary page: tap meal type badge to cycle B/L/D/Any, remove recipes, add from recipe book
- Recipe ratings (1–10): show on swipe cards, recipe list, detail view, plate view
- Kitchen tab: combined shopping list + pantry, swipe to move items in either direction, "All → Pantry" button
- Weekly Overview: totals at top, meals grouped by type
- Dev Reset (DEBUG tab 4): wipes everything including recipes and reseeds with cuisine data
- Global UIKit appearance: wood-tone nav/tab bars, parchment list backgrounds

## What's NOT Working / Known Issues

1. **`MatchingService.swift` is dead code.** The matching logic was migrated inline to `RecipeSwipeView.rankedMatches` to access coordinator state (keyIngredients, selectedCuisines). `MatchingService` is still compiled but nothing calls it. Either delete it or refactor `rankedMatches` to use it.

2. **`GroceryListView.swift` and `PantryView.swift` are orphaned.** They are compiled but not reachable from any tab since `KitchenView` replaced them. They should be deleted or archived.

3. **SwiftData lightweight migration risk.** Two new fields (`cuisine: String`, `rating: Int`) were added to `Recipe`. If a device has an older store, SwiftData's auto-migration may or may not fire. If it fails, `MealPrepApp.init()` catches the error and calls `wipeStore()` — which deletes all user data. This is acceptable for development but should be replaced with a proper `SchemaMigrationPlan` before App Store release.

4. **`MealCountStep.swift` is misnamed.** It no longer contains a meal count stepper — it's purely a cuisine chip picker now. Renaming the file to `CuisineStep.swift` and the struct to `CuisineStep` would reduce confusion, but requires updating `WeeklyPlanningFlow.swift` and re-running xcodegen.

5. **`targetMealCount` is configured but not surfaced.** `FlowCoordinator.targetMealCount` defaults to `7` and the value is stored but nothing in the UI lets the user set it since that stepper was removed. The swipe page simply shows a count of accepted recipes with no ceiling. This is intentional UX-wise but the property is vestigial.

6. **No image caching or compression.** Recipe `imageData` is stored with `.externalStorage` but there's no resize/compress step on PhotosPicker selection. Large photos will be stored full-size.

7. **`RecipeDetailView` modifies `recipe.mealType` directly.** In `WeeklySummaryView.finishAndGoToGrocery()`, meal type overrides are written back to the Recipe model. This means changing a recipe's meal type in the summary permanently changes it in the Recipe Book too. This may or may not be desired behavior.

---

## Important Decisions & Tradeoffs

### 1. FlowCoordinator as pure in-memory state
`FlowCoordinator` is `@Observable` and holds no SwiftData context. All writes to SwiftData happen inside individual step views (via `@Environment(\.modelContext)`). This keeps the coordinator simple and testable, but means each step view must know how to persist its own state.

### 2. Card deck uses `remainingMatches`, not an index
Previous implementation tracked `currentIndex` into a sorted `rankedMatches` array. This caused cards to "cycle back" when the underlying `@Query` data re-sorted on render. The fix was to filter accepted/declined IDs out of `remainingMatches` directly — the deck is always the live filtered set, so no index can go stale.

### 3. `withAnimation` completion callback for swipe (iOS 17 requirement)
The original Task-based approach (`try? await Task.sleep(for: .milliseconds(300))`) caused cards to freeze mid-animation because SwiftUI cancelled in-flight animations when the deck re-rendered. The iOS 17 `withAnimation(_:completionCriteria:_:completion:)` API guarantees the animation completes before state is updated. This is a hard iOS 17 requirement — the app cannot target lower.

### 4. Grocery diff is computed at summary save time, not swipe time
`GroceryDiffService` runs when the user taps "Create Grocery List!" in `WeeklySummaryView`. It diffs selected recipe ingredients against current pantry items and inserts only net-new items into `GroceryItem`. It does not clear existing grocery items first — it only adds missing ones.

### 5. SwiftData migration fallback is a full wipe
`MealPrepApp.init()` wraps `ModelContainer` init in a try/catch. On failure it calls `wipeStore()` which deletes all `.store`, `.store-shm`, `.store-wal` files. This is safe for development/TestFlight but **must be replaced with a `SchemaMigrationPlan` before App Store release** or users will lose all their data on schema updates.

### 6. `PantrySelectionStep.confirm()` replaces all pantry items
Every time the user finishes step 4, the entire `PantryItem` table is wiped and rebuilt from `coordinator.selectedPantryNames`. This is intentional — it re-syncs the pantry to reflect what the user confirmed this week. Any pantry items added outside the flow (via KitchenView) will survive only if they were re-checked in step 4.

### 7. Seed recipes only load on first install
`seedRecipesIfNeeded` is guarded by `fetchCount(FetchDescriptor<Recipe>()) == 0`. After initial seeding, manually added recipes coexist with seeds. The Dev Reset tab now also wipes recipes and reseeds them (to pick up new fields like `cuisine`). This is the only way to get fresh seed data on an existing install without a full reinstall.

### 8. MatchingService.swift vs. inline ranking
`MatchingService` predates the cuisine and key-ingredient features. When those were added, the scoring was built inline in `RecipeSwipeView` because it needed coordinator state (`keyIngredients`, `selectedCuisines`). There's now a structural inconsistency. Long-term, `RecipeMatch` and the ranking logic should live in a service that accepts the full scoring context.

---

## Currently In Progress / Incomplete

- **Nothing actively in progress.** The last session closed all open work items.
- The following are future work that was discussed but not started:
  - Proper SwiftData migration plan (for App Store release)
  - Delete/rename orphaned `GroceryListView.swift`, `PantryView.swift`, and `MatchingService.swift`
  - Rename `MealCountStep` → `CuisineStep`
  - Image compression before storage
  - Push/local notifications for meal prep reminders (not started)

---

## Last Session — Files Touched

This table covers the complete set of changes made in the most recent Cowork session.

| File | What Changed |
|------|-------------|
| `Models/Recipe.swift` | Added `cuisine: String` and `rating: Int` fields; added `ratingDisplay` computed property |
| `Models/CuisineType.swift` | **New file.** 11 cuisine types with emoji; used by MealCountStep and RecipeSwipeView scoring |
| `Planning/FlowCoordinator.swift` | Added `.ingredients` step to enum; added `keyIngredients: [String]`; returning users now start at `.ingredients` not `.pantry`; removed `targetBreakfast/Lunch/Dinner`; added `removeAccepted(_:)` |
| `Planning/WeeklyPlanningFlow.swift` | Added `.ingredients` case routing to `IngredientsEntryStep` |
| `Planning/WeeklySummaryView.swift` | Major rewrite: local `mealTypeOverrides` dict, tappable meal type cycling per recipe, swipe-to-remove, "Add from Recipe Book" sheet (`AddRecipeFromBookSheet`), macros totals card |
| `Planning/Steps/NameEntryStep.swift` | Navigates to `.ingredients` instead of `.pantry`; added `.foregroundStyle` and `.tint` to fix white text on iPhone; forced `.colorScheme(.light)` |
| `Planning/Steps/IngredientsEntryStep.swift` | **New file.** Step 2 of flow: text entry + list of key ingredients with high match weight |
| `Planning/Steps/MealCountStep.swift` | Complete rewrite: removed meal count stepper entirely; now only shows cuisine chip picker; back navigates to `.ingredients` |
| `Planning/Steps/PantrySelectionStep.swift` | Updated copy ("Anything else in stock?"); added back button to `.mealCount`; `confirm()` now navigates to `.swiping` (was `.mealCount`); fixed white text in custom ingredient TextField |
| `Planning/Swipe/RecipeSwipeView.swift` | **Major rewrite.** Fixed animation freeze: now uses `withAnimation` completion callback (iOS 17) instead of `Task.sleep`; added `isAnimating` guard; live macros bar at top; scoring updated with `keyBonus` (+0.25/ingredient) and `cuisineBonus` (+0.2); back button goes to `.pantry` |
| `Planning/Swipe/RecipeCardView.swift` | Added `★ rating` badge to info panel |
| `Planning/Swipe/RecipeDetailCardView.swift` | No structural changes (still shows "Add to plate" button) |
| `Views/Theme/HungiTheme.swift` | Colors updated to cottagecore palette (blush rose harvest, lavender shadow, parchment background) from original Stardew Valley palette |
| `Views/WeeklyOverview/WeeklyOverviewView.swift` | Moved Weekly Totals section to the top of the list |
| `Views/Kitchen/KitchenView.swift` | **New file.** Combined shopping list + pantry. Swipe grocery → pantry ("Got it! ✓"), swipe pantry → grocery ("Need more"), "All → Pantry" button, search across both |
| `Views/Grocery/GroceryListView.swift` | Added "All → Pantry" toolbar button; HungiTheme colors applied; ⚠ no longer in tab bar (orphaned by KitchenView) |
| `Views/Pantry/PantryView.swift` | HungiTheme applied; ⚠ no longer in tab bar (orphaned by KitchenView) |
| `Views/Recipes/RecipeListView.swift` | `RecipeRow` now shows `★ rating` when rated |
| `Views/Recipes/RecipeDetailView.swift` | Changed `let recipe` → `@Bindable var recipe`; added 1–10 rating tap buttons and "Clear" |
| `Views/Recipes/AddEditRecipeView.swift` | Added `cuisine` state variable and `Picker("Cuisine", ...)` using `CuisineType.names` |
| `App/ContentView.swift` | Replaced Pantry + Grocery tabs with single Kitchen tab; `DevResetView` now also deletes recipes and reseeds; added `@Query private var allRecipes` to DevResetView |
| `App/MealPrepApp.swift` | `seedRecipesIfNeeded` changed from `private` to internal (called by DevResetView); seed data updated with `cuisine` field per recipe |

### Where to Start Next Session

1. **Delete orphaned files**: Remove `Views/Grocery/GroceryListView.swift`, `Views/Pantry/PantryView.swift`, and `Services/MatchingService.swift` — none are reachable from the UI and all cause confusion.

2. **Run `xcodegen generate`**: The new `KitchenView.swift` and `IngredientsEntryStep.swift` need to be picked up by the `.xcodeproj`. Also run Dev Reset on device to reseed recipes with cuisine tags.

3. **Rename `MealCountStep`**: The file/struct no longer has anything to do with meal counts. Rename to `CuisineStep` / `CuisineStep.swift` and update `WeeklyPlanningFlow`.

4. **SwiftData migration plan**: Before any TestFlight or App Store build, replace the `wipeStore()` fallback in `MealPrepApp.init()` with a proper `SchemaMigrationPlan` that migrates the `cuisine` and `rating` fields instead of blowing away user data.

5. **Image compression**: In `AddEditRecipeView`, before assigning `imageData`, resize/compress the photo. Raw Photos Library images can be 4–10 MB each.
