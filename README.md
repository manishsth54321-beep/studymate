# StudyMate

A personal academic management app for students. Manage subjects, assignments,
deadlines and study time in one place.

**BCA 6th Semester Project — by Admin**

Built with Flutter (Dart) for the app and Convex as the backend. The Flutter app
talks to the backend over a simple JSON REST API (HTTP actions), same idea as
the architecture diagram in my project poster.

---

## Folder structure

```
StudyMate/
├── frontend/
│   └── studymate/        # Flutter app
│       └── lib/
│           ├── models/       # Subject, Assignment, StudySession
│           ├── screens/      # login, dashboard, subjects, assignments, progress...
│           ├── widgets/      # progress ring, assignment tile
│           ├── providers/    # auth + data state (Provider package)
│           └── utils/        # api client, algorithms, config
├── backend/              # Convex backend
│   └── convex/
│       ├── schema.ts         # users, subjects, assignments, studySessions
│       ├── http.ts           # all REST routes (/api/...)
│       ├── users.ts          # auth functions
│       ├── subjects.ts       # subject CRUD
│       ├── assignments.ts    # assignment CRUD
│       └── studySessions.ts  # study log CRUD
└── README.md
```

## Features

- User authentication (register / login / logout)
- Subject management (add / edit / delete)
- Assignment management with search and subject/status/priority filters
- Deadline tracking — today's tasks, upcoming list, overdue marking
- Study progress — overall ring chart and subject-wise progress bars
- Study session log (minutes per subject, daily and weekly totals)

## Algorithms used

1. **Assignment priority** — due today or tomorrow = High, within 7 days =
   Medium, more than 7 days = Low. (In the add-assignment form the priority
   dropdown is set to "Auto (based on due date)" by default, so this runs
   automatically. You can still force High/Medium/Low yourself.)
2. **Study progress** — Progress = Completed Assignments / Total Assignments × 100.
3. **Upcoming deadlines** — take pending assignments, sort by due date, show the
   nearest 3 on the dashboard.

---

## How to run it

### 1. Backend (Convex)

```bash
cd backend
npm install
npx convex dev
```

The first run asks a couple of questions — pick a new project, and for
`--dev-deployment` choose **local** so everything runs on your own machine for
free. When it starts it prints a line like:

```
✔ Configured a local deployment for http://127.0.0.1:3210
```

The value you need is in `backend/.env.local`:

```
CONVEX_SITE_URL=http://127.0.0.1:3211
```

Keep `npx convex dev` running in one terminal — it pushes your code and reloads
the backend every time you save a file.

### 2. App (Flutter)

Open `frontend/studymate/lib/utils/config.dart` and put the site URL there:

```dart
const String backendUrl = "http://127.0.0.1:3211";
```

| Where you run the app | backendUrl should be |
| --- | --- |
| Windows / Linux desktop | `http://127.0.0.1:3211` |
| Android emulator | `http://10.0.2.2:3211` |
| Real phone (same wifi) | `http://<your-PC-IP>:3211` |

Then:

```bash
cd frontend/studymate
flutter pub get
flutter run
```

### 3. Try it

Register a new account (any email + 6 character password), add a subject like
"DBMS / BCA-301", then add an assignment with a due date. It shows up on the
dashboard under Today's Tasks / Upcoming, and the progress ring moves when you
tick it complete.

---

## Tests

```bash
cd frontend/studymate
flutter test        # 15 tests: priority algorithm, progress calc, labels
cd ../../backend
npx tsc --noEmit    # typecheck the backend
```
