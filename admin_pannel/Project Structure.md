getcarigar-admin/
├── backend/
│   ├── supabase/
│   │   ├── migrations/
│   │   │   └── 001_init_schema.sql
│   │   └── functions/
│   │       ├── calculate_health_state.sql
│   │       ├── get_fleet_summary.sql
│   │       └── archive_vehicle.sql
│   └── api/ (Node.js/Express)
│       ├── routes/
│       │   ├── vehicles.js
│       │   ├── jobs.js
│       │   ├── compliance.js
│       │   └── analytics.js
│       └── controllers/
├── frontend/
│   ├── flutter_web/
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── pages/
│   │   │   │   ├── dashboard.dart
│   │   │   │   ├── vehicle_list.dart
│   │   │   │   ├── vehicle_detail.dart
│   │   │   │   ├── job_management.dart
│   │   │   │   └── analytics.dart
│   │   │   ├── services/
│   │   │   │   └── supabase_service.dart
│   │   │   ├── models/
│   │   │   │   ├── vehicle.dart
│   │   │   │   ├── maintenance_job.dart
│   │   │   │   └── compliance.dart
│   │   │   └── widgets/
│   │   │       ├── vehicle_card.dart
│   │   │       ├── job_card.dart
│   │   │       └── charts.dart
│   │   └── pubspec.yaml
