# GoGreen Fleet Management Admin Dashboard

A professional, production-grade Flutter admin dashboard for fleet management with modern Material Design 3, glassmorphism effects, and responsive layouts.

## Features

### 🎨 Design
- **Material Design 3** with custom color scheme
- **Glassmorphism effects** for modern UI
- **Responsive layouts** (Desktop, Tablet, Mobile)
- **Smooth animations** and transitions
- **Dark mode support**

### 📊 Pages
1. **Dashboard**
   - 6 KPI cards with metrics
   - Fleet health pie chart
   - Maintenance trends line chart
   - Quick action buttons

2. **Vehicle List**
   - DataTable view (desktop)
   - Card list view (mobile)
   - Advanced filtering (status, health state, hub)
   - Real-time search

3. **Vehicle Detail**
   - TabBar navigation (Overview, Jobs, Compliance, History)
   - Vehicle information display
   - Key metrics cards
   - Status badges

4. **Job Management**
   - Job list view
   - Job detail with status timeline
   - Photo gallery grid
   - Cost breakdown

### 🎯 Key Features
- Color-coded status indicators
- Loading skeletons
- Empty states with illustrations
- Toast notifications ready
- Accessibility support
- Performance optimized

## Setup

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   # For web
   flutter run -d chrome
   
   # For mobile
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   ├── app_colors.dart       # Color definitions
│   └── app_theme.dart        # Theme configuration
├── models/
│   ├── vehicle.dart          # Vehicle data model
│   ├── maintenance_job.dart  # Job data model
│   └── compliance.dart       # Compliance document model
├── providers/
│   ├── theme_provider.dart   # Theme state management
│   ├── vehicle_provider.dart # Vehicle state management
│   └── job_provider.dart     # Job state management
├── routes/
│   └── app_router.dart       # Navigation configuration
├── pages/
│   ├── dashboard_page.dart
│   ├── vehicle_list_page.dart
│   ├── vehicle_detail_page.dart
│   └── job_management_page.dart
└── widgets/
    ├── responsive_layout.dart
    ├── sidebar.dart
    ├── bottom_nav.dart
    ├── glass_card.dart
    ├── kpi_card.dart
    ├── status_badge.dart
    ├── charts.dart
    ├── loading_skeleton.dart
    └── empty_state.dart
```

## Color Scheme

- **Primary**: `#2196F3` (Blue)
- **Success**: `#4CAF50` (Green)
- **Warning**: `#FF9800` (Orange)
- **Error**: `#F44336` (Red)
- **Background Light**: `#F5F5F5`
- **Background Dark**: `#1E1E1E`

## Database Integration

The app is designed to work with the Supabase database schema defined in `database.sql`. To connect:

1. Add your Supabase credentials to a config file
2. Update the providers to use actual API calls instead of mock data
3. Implement authentication if needed

## Responsive Breakpoints

- **Mobile**: < 600px (Bottom navigation)
- **Tablet**: 600px - 1024px (Collapsible sidebar)
- **Desktop**: > 1024px (Full sidebar)

## Performance Optimizations

- Lazy loading for images
- Virtual scrolling for large lists
- Optimized re-renders with Provider
- Cached data where appropriate

## Accessibility

- High contrast mode support
- Screen reader friendly labels
- Keyboard navigation
- Touch-friendly target sizes (min 48x48)

## Next Steps

1. **Connect to Backend**: Replace mock data with actual API calls
2. **Add Authentication**: Implement user login/logout
3. **Add More Pages**: Analytics, Settings, Reports
4. **Add Forms**: Create/edit vehicle and job forms
5. **Add Notifications**: Toast notifications for actions
6. **Add Image Upload**: For job photos
7. **Add Export**: PDF/Excel export functionality

## License

This project is part of the GoGreen Fleet Management system.





