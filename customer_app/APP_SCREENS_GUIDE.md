# 📱 Techbes Flutter App - Visual Screens Guide

## App Navigation Structure

```
┌─────────────────────────────────────────────────────────┐
│                    TECHBES APP                           │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───────┐          ┌──────────┐         ┌────────┐
    │ Home  │          │Services  │         │ Cart   │
    │Screen │          │ Screen   │         │Screen  │
    └───────┘          └──────────┘         └────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                    ┌───────────────┐
                    │   Dashboard   │
                    │    Screen     │
                    └───────────────┘
```

## Screen 1: Home Screen 🏠

### Layout
```
┌─────────────────────────────┐
│ Techbes              🛒(3)  │ ← AppBar with cart badge
├─────────────────────────────┤
│                             │
│  ╔═════════════════════╗    │ ← Hero Section (Emerald Gradient)
│  ║ Welcome, John Doe   ║    │
│  ║ Premium IT Services ║    │
│  ║ [Search services]   ║    │
│  ╚═════════════════════╝    │
│                             │
│ Categories                  │
│ ┌────┐ ┌────┐ ┌────┐       │
│ │CCTV│ │Net │ │CyS │...    │ ← Scrollable categories
│ └────┘ └────┘ └────┘       │
│                             │
│ Popular Services            │
│ ┌─────────────────────────┐ │
│ │  HD CCTV Installation   │ │
│ │  [Image] $499.99 ⭐4.8   │ ← Service cards
│ │          [Add]          │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Network Setup Optim.    │ │
│ │  [Image] $799.99 ⭐4.9   │
│ │          [Add]          │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
│ 🏠 🔧 🛒 📊 │ ← Bottom Navigation
```

### Features
- Hero section with gradient (teal to emerald)
- Welcome message with user greeting
- Search bar
- Category filtering (horizontal scroll)
- Popular services display (vertical scroll)
- Service cards with ratings
- Cart badge showing item count

## Screen 2: Services Screen 🔧

### Layout
```
┌─────────────────────────────┐
│ All Services                │ ← AppBar
├─────────────────────────────┤
│ Filter by Category          │
│ [All] [CCTV] [Net] [CyS]... │ ← Chips for filtering
│                             │
│ 8 Services      ☰ Sort      │ ← Sort menu
│                             │
│ ┌─────────────────────────┐ │
│ │  HD CCTV Installation   │ │
│ │  [Image] $499.99 ⭐4.8   │ │
│ │ Professional HD CCTV    │ │
│ │          [Add]          │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Network Setup Optim.    │ │
│ │  [Image] $799.99 ⭐4.9   │ │
│ │ Fast and secure network │ │
│ │          [Add]          │ │
│ └─────────────────────────┘ │
│                             │
│ ... (more services)         │
│                             │
└─────────────────────────────┘
│ 🏠 🔧 🛒 📊 │
```

### Features
- Filter chips by category
- Sort options (rating, price)
- Service cards for all 8 services
- Quick add to cart
- Service descriptions

## Screen 3: Shopping Cart 🛒

### Layout - Empty Cart
```
┌─────────────────────────────┐
│ Shopping Cart               │
├─────────────────────────────┤
│                             │
│          🛒                  │
│   Your cart is empty        │
│  Add services to get started │
│                             │
│     [Browse Services]       │ ← Button
│                             │
└─────────────────────────────┘
│ 🏠 🔧 🛒 📊 │
```

### Layout - With Items
```
┌─────────────────────────────┐
│ Shopping Cart               │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ [Image] HD CCTV         │ │
│ │ CCTV Systems            │ │
│ │ $499.99                 │ │
│ │                       ✕ │ │ ← Remove button
│ │ ─────────────────────── │ │
│ │ Scheduled: May 15, 2025 │ │
│ │ Qty: [−] 1 [+]          │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Network Setup           │ │
│ │ Networking              │ │
│ │ $799.99                 │ │
│ │ ...                     │ │
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│ Subtotal:        $1,299.98  │
│ Tax (10%):         $129.99  │
│ ───────────────────────────  │
│ Total:           $1,429.97  │
│                             │
│ [Proceed to Checkout]       │ ← Action button
│                             │
└─────────────────────────────┘
│ 🏠 🔧 🛒 📊 │
```

### Features
- Display each cart item with image
- Show service details (name, category, price)
- Adjust quantities (−/+)
- Set scheduled dates
- Remove items
- Real-time price calculations
- Tax calculation (10%)
- Checkout button

## Screen 4: Dashboard 📊

### Layout - Not Logged In
```
┌─────────────────────────────┐
│ My Dashboard                │
├─────────────────────────────┤
│                             │
│          👤                  │
│    Sign in to your account  │
│  View your bookings and     │
│  manage services            │
│                             │
│       [Sign In]             │ ← Button
│                             │
└─────────────────────────────┘
│ 🏠 🔧 🛒 📊 │
```

### Layout - Logged In
```
┌─────────────────────────────┐
│ My Dashboard                │
├─────────────────────────────┤
│                             │
│  ╔═════════════════════╗    │ ← Profile Section
│  ║        👤          ║    │    (Emerald background)
│  ║    John Doe        ║    │
│  ║ john@email.com     ║    │
│  ╚═════════════════════╝    │
│                             │
│ Statistics                  │
│ ┌──────────┐ ┌────────┐    │
│ │📦    2   │ │✓   2   │    │ ← Stat cards
│ │Bookings  │ │Confirmed│   │
│ └──────────┘ └────────┘    │
│ ┌──────────┐                │
│ │✕    0    │                │
│ │Cancelled │                │
│ └──────────┘                │
│                             │
│ My Bookings                 │
│ ┌─────────────────────────┐ │
│ │ HD CCTV Installation ✓  │ │
│ │ CCTV Systems            │ │
│ │ ───────────────────────  │ │
│ │ May 15, 2025 | $499.99  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Network Setup        ✓  │ │
│ │ Networking              │ │
│ │ ───────────────────────  │ │
│ │ May 20, 2025 | $799.99  │ │
│ └─────────────────────────┘ │
│                             │
│ [Logout]                    │ ← Logout button
│                             │
└─────────────────────────────┘
│ 🏠 🔧 🛒 📊 │
```

### Features
- User profile section (emerald background)
- Statistics cards (total, confirmed, cancelled)
- Booking history with:
  - Service name and category
  - Scheduled date
  - Amount
  - Status badge (Confirmed/Cancelled)
- Logout button

## Service Card Detail 🎯

### Expanded Service Card
```
┌─────────────────────────────┐
│ ┌──────┐ HD CCTV Installation│
│ │Image │ CCTV Systems     ⭐4.8 │
│ │ 100x │ Professional HD... │
│ │ 100  │ Starting at $499.99│
│ │      │               [Add]│
│ └──────┘                     │
│ ─────────────────────────────│
│                             │
│ Features                    │
│ ✓ 4K Ultra HD Cameras      │
│ ✓ 24/7 Cloud Monitoring    │
│ ✓ Mobile App Access        │
│ ✓ Night Vision             │
│ ✓ Motion Detection         │
│                             │
│ [Show Less]                 │
└─────────────────────────────┘
```

## Add to Cart Dialog 🛍️

```
┌─────────────────────────────┐
│ HD CCTV Installation        │
│                             │
│ Schedule Service Date       │
│ [May 15, 2025]    📅        │
│ (Date picker on click)      │
│                             │
│ Price: $499.99              │
│                             │
│ [Cancel]  [Add to Cart]     │
│                             │
└─────────────────────────────┘
```

## Login Dialog 🔐

```
┌─────────────────────────────┐
│ Sign In                     │
│                             │
│ Email:                      │
│ [_____________________]     │
│                             │
│ Password:                   │
│ [_____________________]     │
│                             │
│ [Cancel]  [Sign In]         │
│                             │
└─────────────────────────────┘
```

## Color Scheme 🎨

```
Primary (Emerald):    #10B981 ████████████████
Accent (Blue):        #3B82F6 ████████████████
Background (Slate):   #F8FAFC ████████████████
Text Dark:            #1E293B ████████████████
Text Light:           #64748B ████████████████
Success (Green):      #10B981 ████████████████
Error (Red):          #EF4444 ████████████████
```

## Navigation Flow 🔀

```
                    Start
                      │
                      ▼
                  ┌─────────┐
                  │  Home   │
                  └────┬────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    Services       ┌─────────┐    Dashboard
    (Browse)       │ Select  │   (View Bookings)
                   │Service  │
        │          └────┬────┘
        │               │
        │               ▼
        │          ┌─────────────┐
        └─────────▶│Add to Cart  │
                   │(Set Date)   │
                   └────┬────────┘
                        │
                        ▼
                    ┌────────┐
                    │ Cart   │
                    │(Review)│
                    └────┬───┘
                         │
                         ▼
                    ┌──────────┐
                    │Checkout  │
                    │(Confirm) │
                    └────┬─────┘
                         │
                         ▼
                    ┌──────────┐
                    │Dashboard │
                    │(View     │
                    │Booking)  │
                    └──────────┘
```

## Data Flow in Cart 🔄

```
Service Card
    │
    ▼
[Add to Cart] Button
    │
    ▼
Date Picker Dialog
    │
    ▼
CartProvider.addToCart()
    │
    ▼
Update Cart State
    │
    ▼
Show Toast Notification
    │
    ▼
Cart Badge Updated
    │
    ▼
Navigate to Cart Screen
```

## Responsive Design 📐

### Mobile (320px - 480px)
- Single column layouts
- Full-width cards
- Bottom navigation
- Touch-optimized buttons

### Tablet (480px - 1024px)
- Two column layouts where applicable
- Larger cards
- Better spacing
- Optimized for 7-10" screens

### All Screens
- Flexible widgets
- MediaQuery for device size
- Overflow handling
- Proper padding/margins

## Interactive Elements 🎮

### Buttons
- **ElevatedButton**: Primary actions (Add to Cart, Checkout, Sign In)
- **OutlinedButton**: Secondary actions (Cancel)
- **TextButton**: Tertiary actions (Show More, View All)

### Input Fields
- **TextField**: Email, password, search
- **DatePicker**: Schedule service date
- **Chips**: Filter by category

### Indicators
- **Badge**: Cart item count
- **Stars**: Service ratings
- **Status Badge**: Booking status (Confirmed/Cancelled)
- **Loading**: While fetching data

---

## Summary

The app follows a **card-based UI** with:
- ✅ Consistent emerald/teal and blue theming
- ✅ Clear information hierarchy
- ✅ Easy navigation with bottom tabs
- ✅ Responsive layouts for all devices
- ✅ Professional interactions and animations
- ✅ Proper loading and error states

**All screens are fully functional with mock data and ready for API integration!**
