# Kaisen UI Design Specification

Status: design and planning only  
Scope: existing Flutter application in mobile/  
Prepared: 16 July 2026

This document defines the visual system and layout direction for the existing Kaisen application. It does not authorize changes to business logic, repositories, providers, models, Supabase, SQL, authentication, RPC calls, persistence, tests, navigation, or screen inventory.

The application keeps these screens and their current routes and workflows:

1. LoginScreen
2. RegisterScreen
3. DashboardScreen
4. CatalogoScreen
5. ProductoDetalleScreen
6. RegistroVentaScreen
7. ScannerScreen
8. HistorialVentasScreen

The current source audit confirms that the app is a task-oriented Flutter mobile product. The current theme is ThemeData with colorSchemeSeed: Colors.indigo and Material 3 enabled. State is supplied by providers, products and sales are accessed through repositories, and the screen files already contain the working forms, scanner flow, cart flow, history filters, and dashboard actions. The future implementation must restyle those surfaces without changing their data or event paths.

## 1. Design principles

### 1.1 Product register

Kaisen is a product UI for operators who need to check stock, find an item, scan a code, and complete a sale with minimal hesitation. The interface should feel like a premium industrial operations instrument, not a marketing site.

Physical scene sentence:

> A shop operator is standing in a dim stockroom or on a sales floor, holding the phone in one hand, checking inventory quickly under uneven lighting while the other hand handles merchandise.

This scene justifies the dark, low-glare canvas, warm text, large numbers, high-contrast controls, and short feedback loops.

Tone references are limited to:

- the clarity of a Zebra enterprise handheld scanner;
- the material restraint of Braun industrial product design;
- the information hierarchy and composure of a high-quality operations tool such as Linear.

These are tone references only. Kaisen must not imitate their branding, copy, or navigation.

### 1.2 Operational clarity

- Show the next useful action before secondary information.
- Make stock, totals, sale confirmation, and errors readable at a glance.
- Use large operational numbers for quantities and money, with tabular figures.
- Keep labels and values visually distinct.
- Avoid decorative cards that do not support a decision or action.

### 1.3 Calm density

- Use strong spacing and a predictable vertical rhythm.
- Prefer one meaningful panel per semantic region over nested cards.
- Keep lists compact enough for field use, but never compress touch targets.
- Use separators, tonal shifts, and typography before adding borders or shadows.

### 1.4 Controlled color

- Acid green is the controlled brand accent for primary actions, selected states, success, and healthy stock.
- Amber is reserved for low stock, caution, and recoverable warnings.
- Red is reserved for errors, destructive actions, unavailable data, and critical states such as zero stock.
- Graphite and translucent surfaces carry most of the interface.
- Color never communicates state by itself. Pair it with text, iconography, or a shape change.

### 1.5 Familiar controls, distinctive surfaces

Keep familiar field, button, chip, list, dialog, and app bar behavior. The Kaisen character comes from palette, hierarchy, surface treatment, and spacing, not from inventing unfamiliar controls.

### 1.6 Field-ready behavior

- Preserve visible labels and form fields exactly.
- Preserve the current navigation stack and screen entry points.
- Keep every primary action available at a minimum 44 logical pixels.
- Respect SafeArea and keyboard insets.
- Support large text without clipping or hiding validation messages.

### 1.7 Restrained glass

Translucency is used only to establish depth around a floating panel or localized overlay. It is not the default treatment for every card. Solid tinted surfaces are preferred for lists, forms, and dense content.

## 2. Color tokens

All values below are exact design tokens. The Flutter literal uses ARGB ordering. The six-digit value is included for handoff clarity.

### 2.1 Canvas and neutral surfaces

| Token | Hex | Flutter literal | Use |
|---|---|---|---|
| ink950 | #0F1211 | 0xFF0F1211 | Main canvas and deepest background |
| ink900 | #141917 | 0xFF141917 | App bar, navigation chrome, recessed regions |
| ink850 | #191F1B | 0xFF191F1B | Primary work surface |
| graphite800 | #222A25 | 0xFF222A25 | Raised panels, active list rows, floating controls |
| graphite700 | #2C362F | 0xFF2C362F | Dialogs, high-emphasis floating surfaces |
| line | #3A473E | 0xFF3A473E | Hairlines and low-emphasis borders |
| lineStrong | #4A5A4B | 0xFF4A5A4B | Focused or selected borders |
| overlay | #0F1211 at 80% | 0xCC0F1211 | Localized scrim behind dialogs or scanner controls |

### 2.2 Text

| Token | Hex | Flutter literal | Use |
|---|---|---|---|
| textPrimary | #F0EEE6 | 0xFFF0EEE6 | Main text, large numbers, active labels |
| textSecondary | #B8B9AE | 0xFFB8B9AE | Supporting text and secondary values |
| textMuted | #858D83 | 0xFF858D83 | Captions, helper text, inactive metadata |
| textDisabled | #5D665E | 0xFF5D665E | Disabled controls and unavailable actions |

### 2.3 Semantic accents

| Token | Hex | Flutter literal | Use |
|---|---|---|---|
| acid400 | #CEFF69 | 0xFFCEFF69 | Bright end of a primary action gradient, focus highlight |
| acid500 | #B9F24A | 0xFFB9F24A | Main accent, primary action, success, healthy stock |
| acid700 | #7EA72E | 0xFF7EA72E | Pressed or darkened accent state |
| acidSurface | acid500 at 8% | 0x14B9F24A | Subtle positive or selected background |
| acidBorder | acid500 at 28% | 0x47B9F24A | Selected or positive border |
| amber400 | #FFCB68 | 0xFFFFCB68 | Warning emphasis on dark surfaces |
| amber500 | #F2B84B | 0xFFF2B84B | Low stock and caution |
| amberSurface | amber500 at 10% | 0x1AF2B84B | Warning panel background |
| amberBorder | amber500 at 35% | 0x59F2B84B | Warning panel border |
| red400 | #FF7D72 | 0xFFFF7D72 | Critical emphasis and error icon |
| red500 | #F26960 | 0xFFF26960 | Errors, destructive actions, zero stock |
| redSurface | red500 at 10% | 0x1AF26960 | Error and critical panel background |
| redBorder | red500 at 35% | 0x59F26960 | Error and destructive focus border |

### 2.4 Token usage rules

- Map colorScheme.surface to ink850, surfaceContainer to graphite800, and surfaceContainerHighest to graphite700.
- Map colorScheme.primary to acid500 and onPrimary to ink950.
- Map colorScheme.secondary and warning presentation to amber500, with ink950 text on filled amber controls.
- Map colorScheme.error to red500 and onError to ink950.
- Use textPrimary on ink950, ink900, ink850, and graphite800.
- Use textSecondary for supporting copy. Use textMuted only when the text remains at least 4.5:1 against its actual surface.
- Do not use Material indigo, default Material green, saturated blue, or arbitrary per-screen colors.
- Do not use red for ordinary low stock. A product with stock from 1 through 5 is amber. A product with stock 0 is red because it is unavailable and critical.
- Do not use gradients in text. Use one solid text token and weight or size for emphasis.

## 3. Typography scale

Use the platform system sans with no new font dependency. Roboto is the Android baseline and the platform sans fallback is acceptable on other targets. Do not introduce a display font or a decorative typeface.

All sizes are logical pixels and should be implemented as fixed product-UI sizes, not fluid viewport typography.

| Role | Size | Line height | Weight | Letter spacing | Use |
|---|---:|---:|---:|---:|---|
| Display | 36 | 40 | w700 | -0.8 | Kaisen auth lockup or exceptional full-screen metric |
| Operational metric | 32 | 36 | w700 | -0.6 | Dashboard counts, total earnings |
| Screen title | 28 | 32 | w700 | -0.4 | Large title treatment when an app bar title is not enough |
| Section title | 18 | 24 | w600 | -0.1 | Accesos rápidos, Productos con poco stock |
| Body large | 16 | 24 | w400 | 0 | Important supporting copy |
| Body | 14 | 20 | w400 | 0 | List metadata and normal copy |
| Label | 13 | 16 | w600 | 0.1 | Form labels, buttons, chip labels |
| Caption | 12 | 16 | w500 | 0.1 | Timestamps, secondary metadata, helper copy |
| Micro label | 11 | 14 | w700 | 0.8 | Very short status labels only, never long sentences |

Typography rules:

- Use textPrimary for screen titles, values, and primary actions.
- Use textSecondary for context and textMuted for tertiary metadata.
- Use tabular figures for money, stock counts, quantities, and dates when available.
- Use weight and spacing to create hierarchy. Do not rely on uppercase text or color alone.
- Do not reduce body text below 14 for essential instructions, form labels, error copy, or action labels.
- Let Spanish labels wrap naturally when text scaling is increased. Never clip or ellipsize validation messages.

## 4. Spacing scale

Use a 4 logical pixel base unit.

| Token | Value | Primary use |
|---|---:|---|
| space1 | 4 | Icon-to-label micro gap |
| space2 | 8 | Caption grouping, compact row gap |
| space3 | 12 | Chip gap, list row inner gap |
| space4 | 16 | Standard panel padding, form field gap |
| space5 | 20 | Screen gutter, large control padding |
| space6 | 24 | Section separation, auth form rhythm |
| space7 | 32 | Major content group separation |
| space8 | 40 | Auth lockup separation, large empty-state breathing room |
| space9 | 48 | Large action separation or scanner framing |
| space10 | 64 | Top-level atmospheric breathing room |

Layout rules:

- Use 20 logical pixels as the default mobile screen gutter, increasing to 24 on wider layouts.
- Use 16 logical pixels inside standard surfaces and 20 for high-emphasis floating panels.
- Keep at least 24 logical pixels between unrelated dashboard sections.
- Keep at least 12 logical pixels between a control and its supporting metadata.
- Use 8 logical pixels between adjacent chips and 12 logical pixels between list rows.
- Reserve bottom space for SafeArea and the on-screen keyboard before placing fixed action summaries.

## 5. Radius scale

| Token | Value | Use |
|---|---:|---|
| radiusSmall | 8 | Small icon containers and compact secondary surfaces |
| radiusControl | 12 | Text fields, outlined buttons, standard buttons |
| radiusPanel | 16 | List rows and standard panels |
| radiusFloating | 20 | Dashboard summary panels, cart summary, dialogs |
| radiusLarge | 28 | Auth brand panel or a major empty state container |
| radiusPill | 999 | Choice chips, stock badges, compact status controls |

Radius rules:

- Use radiusFloating for a semantic floating panel, not for every row.
- Keep adjacent surfaces from stacking multiple rounded rectangles inside one another.
- Use the same radius for the entire hit target and its visible background.
- The scanner frame uses radiusFloating and a 2 logical pixel stroke.

## 6. Elevation and shadow rules

Kaisen uses tonal separation first and shadow second. Material card elevation must not create a generic raised-card appearance.

| Level | Shadow token | Flutter literal | Geometry | Use |
|---|---|---|---|---|
| E0 | none | none | No shadow | Canvas, flat sections, list background |
| E1 | soft | 0x380B0E0D | blur 16, y 6, spread 0 | One raised panel per section |
| E2 | float | 0x5C0B0E0D | blur 28, y 12, spread -4 | Cart summary, floating action, dialog |
| Focus | acid focus | 0x3DB9F24A | blur 0, y 0, spread 2 | Focused control or selected surface |
| Critical focus | red focus | 0x3DF26960 | blur 0, y 0, spread 2 | Destructive or error-focused action |

Rules:

- Set ordinary list rows to E0 or a very soft E1. Do not shadow every item in a long list.
- Use a 1 logical pixel line border before increasing shadow strength.
- Avoid pure black shadows. Use the tinted shadow token above.
- Do not use colored side stripes as accents on panels or rows. Use a full border, tonal background, or semantic icon.
- A screen should normally have no more than two E1 or E2 surfaces visible at once.
- Preserve focus visibility even when elevation is removed.

## 7. Gradient recipes

Gradients are static atmosphere and depth tools. They are not a substitute for hierarchy.

### 7.1 Atmospheric canvas

Use one radial gradient behind the screen content:

- Center: approximately Alignment(0.78, -0.92)
- Radius: 1.2
- Stops: acid500 at 6% opacity, acid500 at 0%, ink950 at 100%
- Colors: 0x0FB9F24A, 0x00B9F24A, 0xFF0F1211

The accent should be barely perceptible. It must not look neon or like a gaming HUD.

### 7.2 Graphite wash

Use for app bar or a broad content transition:

- Direction: top-left to bottom-right
- Colors: ink900 to ink950
- No animated stops

### 7.3 Primary action

Use only for the primary filled action:

- Direction: top-left to bottom-right
- Colors: acid400 to acid500
- Pressed state: solid acid700
- Text and icon: ink950

Do not use this gradient for metrics, headings, tags, or decorative borders.

### 7.4 Warning halo

Use only behind a low-stock or caution surface:

- Center: top-left
- Colors: amber500 at 10%, amber500 at 0%, ink850 at 100%
- Flutter colors: 0x1AF2B84B, 0x00F2B84B, 0xFF191F1B

### 7.5 Surface sheen

Use as a subtle top-left sheen on one floating panel:

- Colors: textPrimary at 6%, textPrimary at 0%
- Flutter colors: 0x0FF0EEE6, 0x00F0EEE6
- One application per panel, no repeating pattern

Do not use large raster backgrounds, animated gradients, gradient text, or multiple overlapping gradients on a dense screen.

## 8. Surface hierarchy

| Layer | Surface | Visual treatment | Content |
|---|---|---|---|
| L0 | Work canvas | ink950 with atmospheric radial gradient | Screen background and scroll space |
| L1 | Chrome | ink900, mostly opaque | App bars and localized navigation chrome |
| L2 | Work surface | ink850, 1px line when needed | Forms, search region, grouped list areas |
| L3 | Raised panel | graphite800, optional E1, optional sheen | Metrics, warning panels, cart summary |
| L4 | Floating surface | graphite700, E2, 1px lineStrong | Dialogs and truly floating controls |

Surface rules:

- Start with the L0 canvas and place content directly on it.
- Use L2 for a semantic region, not as a wrapper around every widget.
- Use L3 for panels that summarize or require attention.
- Use L4 only for dialogs and transient elements.
- Glass treatment means a translucent tint plus a thin border. It does not automatically mean blur.
- The preferred implementation for most panels is an opaque graphite surface with a small alpha sheen.
- BackdropFilter is not used on the dashboard, catalog list, forms, history list, or cart list.
- A localized blur may be considered for a small scanner toolbar or transient overlay only after performance validation. Maximum one localized blur region per screen.

## 9. Iconography rules

Use the existing Material Icons font. Do not add an icon package or raster icon assets.

Preferred visual language:

- Use outlined icons for navigation, list rows, and secondary actions.
- Use filled icons only for the primary action or when the icon must read over a camera feed.
- Default icon size is 20 logical pixels inside a control and 24 inside a 48 logical pixel hit target.
- Use 32 logical pixels only for a primary metric or an empty state illustration.
- Keep icon color semantic: textSecondary for neutral, acid500 for positive/selected, amber500 for warning, red500 for error/destructive.
- Do not put an icon in every row purely for decoration.
- Every icon-only action must retain a tooltip or accessible label. Existing tooltips such as Sincronizar con el servidor, Cerrar sesión, and Vaciar carrito remain.
- Pair critical state icons with visible state text. A warning triangle alone is insufficient.

Existing icon intent to preserve:

| Action or state | Preferred icon family |
|---|---|
| Inventory | inventory_2_outlined |
| Low stock | warning_amber_rounded |
| Sales | point_of_sale or payments_outlined |
| History | receipt_long |
| Search | search |
| Scan | qr_code_scanner |
| Sync | sync |
| Logout | logout |
| Delete | delete_outline |
| Add | add |

## 10. Animation durations and curves

Motion communicates state, feedback, or hierarchy. It must never delay an operator who is trying to scan or sell.

| Motion | Duration | Curve | Rule |
|---|---:|---|---|
| Press or tap response | 100 ms | Curves.easeOut | Small scale or tonal response only |
| Focus and border change | 140 ms | Curves.easeOutCubic | Do not move layout |
| Enabled, disabled, or selected state | 160 ms | Curves.easeOutCubic | Animate color and opacity, not size |
| Loading-to-content swap | 180 ms | Curves.easeOutCubic | Use AnimatedSwitcher without page choreography |
| Panel or inline warning reveal | 220 ms | Curves.easeOutCubic | Reveal in place; preserve scroll position |
| Existing screen transition styling | 240 ms | Curves.easeInOutCubic | Preserve current MaterialPageRoute navigation semantics |
| Skeleton shimmer, if needed | 1200 ms | Curves.linear | One shared animation, disabled for reduced motion |

Rules:

- Do not animate layout properties for long durations.
- Do not use bounce, elastic, spring, or infinite decorative motion.
- Do not orchestrate a sequence of dashboard cards on page load.
- The scan frame is static. A continuous pulsing frame would compete with detection.
- A successful sale may use a short success-state swap or snackbar transition, but it must keep the existing success feedback path.
- Respect the operating system reduced-motion preference by disabling nonessential motion.

## 11. Loading, empty, success, warning, and error states

### 11.1 Shared state vocabulary

#### Loading

- Preserve the existing loading flags and action disabling.
- Use 2 to 4 static skeleton rows or blocks that match the final geometry for inventory and history.
- Use a compact acid-tinted progress indicator inside a blocking action such as Iniciar sesión, Registrarme, Guardar cambios, or Confirmar venta.
- Use a full-screen progress indicator only when there is no stable content to keep visible.
- Never display a blank dark screen while content is loading.

#### Empty

- Keep the current empty-state copy and workflow.
- Use a single quiet outlined icon, a short text block, and the nearest existing action when one already exists.
- Do not create a new screen or modal for an empty result.
- Empty states should be visually quieter than success or warning states, using textSecondary and line tokens.

#### Success

- Use acidSurface, acid500, and a positive icon.
- Keep current success SnackBar behavior and labels. Restyle the SnackBar as a compact floating L3 surface with a 1px acidBorder.
- Success feedback must not block the next operation.

#### Warning

- Use amberSurface, amber500, and warning_amber_rounded.
- Low stock, a product not found after scanning, and a recoverable caution are warnings.
- Keep the warning inline near the action that caused it.
- Do not use red for low stock from 1 through 5.

#### Error and critical

- Use redSurface, red500, redBorder, and a clear error icon.
- Keep current provider error text and current SnackBar or dialog path. Change visual treatment only.
- Red is appropriate for connection errors, invalid operations, duplicate barcode, stale version, insufficient stock, unavailable products, destructive confirmation, camera access failure, and zero stock.
- Do not expose technical error details that are not already part of the safe user-facing contract.

### 11.2 Screen state matrix

| Screen | Loading | Empty or no result | Success | Warning | Error or critical |
|---|---|---|---|---|---|
| LoginScreen | Disable Iniciar sesión; show compact indicator in the button | Not applicable | AuthGate continues to DashboardScreen as it does now | Not applicable | Restyled existing SnackBar for invalid credentials, connection, or configuration |
| RegisterScreen | Disable Registrarme; show compact indicator in the button | Not applicable | Preserve pop back to LoginScreen | Not applicable | Restyled existing SnackBar for duplicate username or registration failure |
| DashboardScreen | Skeleton metrics and product rows while providers load | Preserve Todo el inventario tiene stock saludable. when no low-stock products exist | Acid success SnackBar after sync, including Ya estaba todo sincronizado. | Low-stock metric and list use amber; sync-in-progress uses neutral disabled chrome | Sync error dialog keeps Cerrar and uses red critical surface |
| CatalogoScreen | Skeleton product rows | Preserve No hay productos que coincidan. | Refresh keeps existing list and filter state | No result after a search is neutral empty, not a warning | Repository/load failure uses red error treatment with existing provider message |
| ProductoDetalleScreen | Disable save and show progress while saving | Not applicable | Preserve pop after create/update | Optional barcode and zero initial stock remain visually clear, not warnings by default | Validation stays adjacent to fields; delete confirmation and repository failures use red |
| RegistroVentaScreen | Show compact progress while barcode lookup or confirmation is active | Preserve Tu carrito está vacío. Escanea un producto para comenzar. | Preserve Venta registrada: ... SnackBar with acid success styling | Preserve the not-found inline panel in amber, including Crear producto con este código | Insufficient stock, unavailable product, idempotency conflict, or connection failure use red error feedback |
| ScannerScreen | Camera feed is the loading surface; do not cover it with a spinner unless the camera package supplies an error state | Not applicable | Return the first detected code through the existing pop flow | Torch state may use acid selected styling | Preserve camera error text in a high-contrast red-tinted scrim |
| HistorialVentasScreen | Skeleton rows and summary metric | Preserve Todavía no hay ventas registradas. and No hay ventas en esta categoría. | Filter and sort changes are immediate, with a 160 ms selected-state transition | No category result is neutral empty, not amber | History load failure uses the existing provider message with red error treatment |

## 12. Accessibility and contrast rules

- Target at least 4.5:1 for normal text and 3:1 for large text. Treat 4.5:1 as the default target for all essential text.
- Validate contrast against the final composited surface, not only the base token. Alpha surfaces must be checked over ink950 and ink850.
- Use textPrimary for all essential content. textMuted is not acceptable for form labels, button labels, errors, or operational values.
- Maintain a visible 2 logical pixel focus ring using acidBorder and a tonal change. Do not rely on hover or color alone.
- All icon-only controls must have a tooltip or semantic label. Preserve the current tooltips and add semantic labels to any future icon-only visual widget.
- Minimum hit target is 44 by 44 logical pixels. Use 48 by 48 for IconButton, chip, and compact control hit areas whenever layout allows.
- Keep visible field labels. Hints such as Buscar producto... supplement a field and do not replace its accessible label.
- Validation text must remain adjacent to its field and must be announced through the normal Flutter form semantics.
- Pair color with text and icon shape: Stock: 4 plus amber, Stock: 0 plus red, and a warning or critical icon.
- Support text scaling up to 200% without clipped actions, overlapping fields, or inaccessible bottom summaries.
- Use SafeArea, respect keyboard insets, and keep bottom actions above the system gesture area.
- Do not use motion as the only indication of a change. Reduced-motion users must receive the same information.
- Keep tap targets separated by at least 8 logical pixels where possible to reduce accidental activation.
- Prefer logical reading order: title, context, primary action, content, secondary action.
- Do not place essential text over a camera feed without a scrim.

## 13. Screen-by-screen visual structure

All structures below preserve the existing screen names, labels, fields, navigation entries, and provider callbacks.

### 13.1 LoginScreen

Current entry: AuthGate when there is no authenticated user.

Structure:

1. L0 atmospheric canvas with a quiet radial acid glow in the upper-right.
2. Centered auth content with a maximum readable width of approximately 360 logical pixels.
3. Brand lockup: inventory icon in a small graphite800 mark, Kaisen in Display, and Gestión de inventario in Body.
4. Form panel on L2 or directly on the canvas, with no nested card. Keep the existing fields Usuario and Contraseña.
5. Iniciar sesión as the sole primary filled action, minimum 48 logical pixels high.
6. ¿No tienes cuenta? Regístrate as the secondary text action below the primary action.
7. Existing validation stays in the form. Existing authentication errors remain SnackBars, restyled red.

Visual details:

- The brand icon uses textPrimary or acid500, not indigo.
- Fields use graphite800 fill, line border, 12 radius, persistent label, and acid focus ring.
- Password obscuring and all controller behavior remain unchanged.
- The auth surface must feel quiet and dependable, not like a neon splash screen.

### 13.2 RegisterScreen

Current entry: pushed from LoginScreen. Back behavior remains unchanged.

Structure:

1. L1 app bar with the existing title Crear cuenta and the normal back affordance.
2. Centered or top-weighted form column with the same maximum width as LoginScreen.
3. Keep the current fields in order: Usuario, Contraseña, Confirmar contraseña.
4. Keep the current validators and their messages.
5. Registrarme is the primary action at the end of the form.

Visual details:

- Use a compact page title treatment so the three-field form remains visible above the keyboard.
- Keep 16 logical pixels between fields and 24 before the primary action.
- Loading disables the button and replaces only its content with the compact progress indicator.
- Registration success continues to pop the screen; do not add a success screen.

### 13.3 DashboardScreen

Current entry: AuthGate after authentication. Existing AppBar actions remain.

Structure:

1. L0 canvas with L1 app bar.
2. App bar title remains Hola, [usuario]; sync and logout remain icon actions.
3. First content block is a two-column metric group:
   - Productos activos with an operational number and inventory icon.
   - Stock bajo with an operational number and amber warning icon.
4. Second block is the Ganancias totales panel, clickable to the existing HistorialVentasScreen route. Use a large acid metric and a right chevron.
5. Section title Accesos rápidos.
6. Full-width primary action Registrar venta.
7. Two equal secondary controls: Catálogo and Nuevo producto.
8. Full-width secondary control Ver ventas.
9. Section title Productos con poco stock.
10. Existing low-stock ProductoCard rows or the current healthy-stock empty message.

Visual details:

- The metric numbers must be the strongest visual elements after the greeting.
- Stock bajo is amber, not red. Zero-stock products in the list are red critical.
- Use one L3 panel for earnings and one compact tonal treatment for each metric. Do not wrap every quick action in a card.
- The sync icon shows a compact progress indicator while syncing. The action remains disabled as it does now.
- Pull-to-refresh remains available through the current RefreshIndicator, with the indicator recolored acid500.
- The dashboard must not become a grid of identical statistic cards.

### 13.4 CatalogoScreen

Current entry: DashboardScreen and existing product-related flows.

Structure:

1. L1 app bar with Catálogo de inventario.
2. Search field directly below the app bar, with the current hint Buscar producto... and search/clear affordances.
3. Horizontal category ChoiceChip row, preserving Todas and every loaded category.
4. Product list on the L0 canvas or within one L2 list region.
5. Existing ProductoCard rows with product name, category, price, and Stock: [n].
6. Existing floating add action remains the route to ProductoDetalleScreen in create mode.

Visual details:

- The search field is a graphite800 control with a 12 radius and a 48 logical pixel height.
- Selected category chips use acidSurface, acidBorder, and acid500 text. Unselected chips use graphite800 and textSecondary.
- Do not use a separate elevated card behind every product row. Use a subtle row divider or alternating tonal separation.
- The list remains refreshable through the existing RefreshIndicator.
- Search and category filtering remain provider calls with the current behavior.

### 13.5 ProductoDetalleScreen

Current entry: create, edit, or barcode-not-found flow.

Structure:

1. L1 app bar with Nuevo producto or Editar producto.
2. Preserve the existing delete icon only in edit mode.
3. One form column, with fields in the current order:
   - Nombre
   - Precio
   - Stock inicial
   - Categoría
   - Código de barras (opcional)
4. Guardar cambios or Crear producto remains the single primary action.
5. Delete confirmation remains a dialog with Eliminar producto, Cancelar, and Eliminar.

Visual details:

- Use graphite800 fields with persistent labels and a clear focus ring.
- Keep Precio currency prefix visible without reducing the editable area.
- Keep the barcode field visually associated with the QR icon but do not turn it into a new scanner flow.
- The delete action is red because it is destructive and critical. It is not a decorative red accent.
- Save loading state changes only the button content and disabled state.
- Validation text uses red500 and remains immediately below the relevant field.

### 13.6 RegistroVentaScreen

Current entry: DashboardScreen. ScannerScreen remains a pushed child flow.

Structure:

1. L1 app bar with Registro de venta and the existing Vaciar carrito icon action when the cart is non-empty.
2. Full-width primary scan action:
   - Escanear producto when empty.
   - Escanear otro producto when the cart has items.
3. Inline lookup progress state below the scan action.
4. Existing not-found warning panel with the scanned code and Crear producto con este código.
5. Cart item list with product name, unit price, subtotal, quantity controls, and delete action.
6. Floating or bottom-pinned L3 cart summary with Total and Confirmar venta.

Visual details:

- The scan action is the strongest action when the cart is empty.
- Quantity controls remain familiar and each hit area is at least 44 by 44 logical pixels.
- Use acid for the total and primary confirmation only when it is actionable. Use red for a blocked confirmation or critical stock failure.
- The cart summary must respect SafeArea and keyboard insets.
- The current VentaProvider cart methods and sale confirmation path remain unchanged.
- The empty-cart copy remains Tu carrito está vacío. Escanea un producto para comenzar.

### 13.7 ScannerScreen

Current entry: pushed only from RegistroVentaScreen.

Structure:

1. Full-screen camera feed remains the functional background.
2. Use a localized L1 or translucent toolbar for Escanear código and torch action. Do not blur the full screen.
3. Center the existing 260 by 160 scan frame with a 2 logical pixel textPrimary or acid stroke and radiusFloating.
4. Keep the instruction Apunta la cámara al código de barras o QR at the bottom, above SafeArea.
5. Camera errors use a localized red-tinted scrim with readable text.

Visual details:

- The scan frame is static and high contrast. No pulsing, rotating, or animated HUD treatment.
- The torch action uses an icon-only 48 logical pixel target and a semantic label.
- Do not add a camera permission screen or a new confirmation screen. Preserve the first-detected-code pop behavior.

### 13.8 HistorialVentasScreen

Current entry: DashboardScreen and the existing earnings panel.

Structure:

1. L1 app bar with Historial de ventas.
2. L3 earnings panel with Ganancias totales, a large acid amount, and the existing registered-sales count.
3. Horizontal category ChoiceChip row, preserving Todas and loaded categories.
4. Sort row with Ordenar:, Recientes, and Monto más alto.
5. History list with receipt icon, product name, category, quantity, unit price, formatted date, and total.
6. Existing empty messages remain centered in the list region.

Visual details:

- The total amount is the primary visual anchor, but the screen should not resemble a marketing KPI dashboard.
- Category and sort chips share one vocabulary with CatalogoScreen.
- History rows use a compact L2 or divider treatment. Avoid individual heavy shadows.
- Refresh remains available through the existing RefreshIndicator.
- Filter and sort changes remain immediate provider state changes with only a short selected-state animation.

## 14. Reusable Flutter component inventory

These components describe visual responsibilities only. They must receive data and callbacks from existing screens and providers; they must not own repositories, persistence, navigation policy, or business rules.

### 14.1 Theme and tokens

- KaisenTokens: colors, spacing, radii, shadows, gradients, and motion constants from sections 2 through 10.
- KaisenTheme: dark ThemeData, ColorScheme, AppBarTheme, InputDecorationTheme, button themes, CardTheme, ChipTheme, DialogTheme, SnackBarTheme, and focus styling.

### 14.2 Surfaces and hierarchy

- KaisenSurface: an opaque or lightly translucent rounded surface with border, optional sheen, and controlled elevation.
- KaisenMetricPanel: large operational number, label, semantic icon, and optional tap callback. It must not contain provider logic.
- KaisenActionGroup: spacing and alignment wrapper for primary and secondary controls, without changing callbacks.

### 14.3 Controls and forms

- KaisenFormControl: visual wrapper for the existing TextFormField decoration, focus border, error border, label, prefix, suffix, and minimum height. It must not own controllers or validators.
- KaisenPill: shared visual treatment for category and sort ChoiceChip states.
- KaisenPrimaryButton and KaisenSecondaryButton: visual variants that preserve existing button labels, callbacks, disabled states, and progress indicators.

### 14.4 Feedback and specialized visuals

- KaisenStateView: shared loading skeleton, empty, warning, and error geometry. It receives copy and icon data from the screen.
- KaisenBrandMark: the visual Kaisen lockup shared by LoginScreen and, if useful, RegisterScreen.
- KaisenScannerOverlay: static scan frame and camera-feed scrim geometry. It does not control detection or torch behavior.

### 14.5 Existing widgets to restyle

- mobile/lib/widgets/producto_card.dart: preserve product data, tap callback, and row semantics. Apply L2/L0 row treatment, typography, and the stock status mapping.
- mobile/lib/widgets/stock_badge.dart: preserve Stock: [n] text and inputs. Use acid for healthy stock, amber for 1 through 5, and red for zero.

Do not create a generic card component that is then used for every region. The component inventory should support a coherent vocabulary while allowing the dashboard, cart summary, and history list to have different information densities.

## 15. Performance restrictions for blur and animations

- Do not use large image assets as screen backgrounds. Use DecoratedBox, CustomPaint, and lightweight gradients.
- Do not use BackdropFilter on the whole scaffold, dashboard, catalog list, forms, history list, or cart list.
- Prefer zero blur. If a localized blur is necessary for a small scanner toolbar or transient overlay, use at most one instance per screen, keep the region small, and validate on a mid-range Android device.
- Do not place blur or a shadow on every list row.
- Do not animate a full-screen gradient, camera frame, list background, or metric number continuously.
- Use one shared skeleton animation instead of one animation controller per row.
- Keep animations under 240 ms except the optional 1200 ms skeleton shimmer.
- Prefer opacity, color, and transform changes over layout changes.
- Keep the camera preview and scanner overlay on separate lightweight layers. Do not repaint the entire screen for torch or detection feedback.
- Use const widgets wherever inputs are static and avoid rebuilding unchanged list content.
- Do not add a dependency for animation, blur, iconography, fonts, or backend services.
- Any future visual widget must be profiled with a long product list and with the camera screen active.
- Reduced-motion mode must disable shimmer and nonessential transitions.

## 16. Exact files that should eventually be created

This design phase creates only docs/UI_DESIGN_SPEC.md. The following are the exact new UI-only files planned for a later implementation phase:

1. mobile/lib/theme/kaisen_tokens.dart
2. mobile/lib/theme/kaisen_theme.dart
3. mobile/lib/widgets/kaisen_surface.dart
4. mobile/lib/widgets/kaisen_metric_panel.dart
5. mobile/lib/widgets/kaisen_form_control.dart
6. mobile/lib/widgets/kaisen_state_view.dart
7. mobile/lib/widgets/kaisen_brand_mark.dart
8. mobile/lib/widgets/kaisen_scanner_overlay.dart

Existing UI and layout files that may be edited later, without changing their logic:

1. mobile/lib/main.dart, theme wiring only
2. mobile/lib/screens/login_screen.dart
3. mobile/lib/screens/register_screen.dart
4. mobile/lib/screens/dashboard_screen.dart
5. mobile/lib/screens/catalogo_screen.dart
6. mobile/lib/screens/producto_detalle_screen.dart
7. mobile/lib/screens/registro_venta_screen.dart
8. mobile/lib/screens/scanner_screen.dart
9. mobile/lib/screens/historial_ventas_screen.dart
10. mobile/lib/widgets/producto_card.dart
11. mobile/lib/widgets/stock_badge.dart

No new screen files, route files, provider files, repository files, model files, Supabase files, SQL files, authentication files, persistence files, or test files are part of this design plan. No existing screen is renamed, removed, merged, or split.

## 17. Phased implementation plan

The following is a future implementation plan only. It is not being executed in this design phase.

### Phase 0: baseline and visual guard

Scope:

- Capture the current screen inventory and visible labels.
- Confirm the existing navigation and provider callbacks.
- Confirm the allowed file boundary from AGENTS.md.
- Create no Flutter source changes.

Validation:

~~~text
cd mobile
flutter analyze
flutter test
~~~

Record the results before proceeding. If the Flutter executable is unavailable, record that as an environment blocker rather than changing project files.

### Phase 1: tokens and app theme

Scope:

- Create kaisen_tokens.dart and kaisen_theme.dart.
- Wire the theme through the existing visual theme location in main.dart.
- Replace the indigo seed and default Material appearance with the token mapping in this document.
- Do not change providers, repositories, models, authentication, RPC calls, persistence, routes, or labels.

Validation gate:

- Run flutter analyze.
- Run flutter test.
- Confirm that only theme files and the permitted main.dart theme wiring changed.
- Confirm that all existing tests still pass.

### Phase 2: shared visual widgets

Scope:

- Create the shared surface, metric, form-control, state, brand, and scanner-overlay widgets listed in section 16.
- Restyle the existing ProductoCard and StockBadge.
- Keep callbacks, input values, validator functions, provider reads, and navigation calls in the existing screen owners.

Validation gate:

- Run flutter analyze.
- Run flutter test.
- Verify 44 logical pixel hit targets and focus states.
- Test a long catalog and history list for excessive shadows, rebuilds, or blur.

### Phase 3: authentication and inventory layouts

Scope:

- Apply the theme and shared widgets to LoginScreen, RegisterScreen, DashboardScreen, CatalogoScreen, and ProductoDetalleScreen.
- Preserve every current label, field, validator, snackbar, dialog, route, and callback.
- Confirm the dashboard remains an operational overview rather than a repeated card grid.

Validation gate:

- Run flutter analyze.
- Run flutter test.
- Manually verify register, login, dashboard refresh/sync/logout, catalog search/filter, create/edit/archive, and barcode-prefilled product creation.

### Phase 4: sales, scanner, and history layouts

Scope:

- Apply the theme and shared widgets to RegistroVentaScreen, ScannerScreen, and HistorialVentasScreen.
- Preserve the scanner pop result, cart quantity behavior, confirmation path, empty-cart path, not-found path, history filters, and sort controls.
- Keep the camera surface free of large raster decoration and full-screen blur.

Validation gate:

- Run flutter analyze.
- Run flutter test.
- Manually verify scanning, torch access, camera error presentation, cart quantity limits, sale confirmation, stock failure, history filtering, sorting, and refresh.

### Phase 5: accessibility, performance, and regression acceptance

Scope:

- Verify contrast on real composited surfaces.
- Verify text scaling, SafeArea, keyboard behavior, reduced motion, and screen-reader labels.
- Profile the catalog, history, dashboard, and scanner on a mid-range Android device.
- Remove any unnecessary blur, animation, shadow, or nested surface discovered during review.

Final validation gate:

- Run flutter analyze.
- Run flutter test.
- Confirm no non-UI file was changed.
- Confirm all eight existing screens remain present and reachable through the same workflows.
- Confirm no external dependency or large image asset was added.

No implementation should begin until this specification is accepted. This document is the complete design handoff for the visual redesign; it does not itself change the application.
