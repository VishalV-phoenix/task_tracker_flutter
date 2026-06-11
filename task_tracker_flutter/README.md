# Trackeon

A mobile-first personal productivity app built with Flutter for managing tasks, projects, learning goals, roadmaps, reminders, archives, and personal progress tracking.

Trackeon started as a browser-based productivity dashboard and was later rebuilt as a Flutter application. The project was developed primarily through a **vibe-coding workflow**, using AI tools to rapidly prototype, iterate, debug, and refine ideas into a working mobile app.

---

## Screenshots

### Dashboard

![Dashboard](screenshots/dashboard.jpg)

The central productivity hub showing categories, overall progress, quick statistics, and roadmap progress.

### Kanban Task Management

![Task Board](screenshots/kanban_board.jpg)

![Task Board](screenshots/task_board.jpg)

Manage tasks using a Kanban workflow with To Do, In Progress, and Completed states.

### Roadmap Tracking

![Roadmap](screenshots/roadmap.jpg)

Track long-term goals through milestones, checkpoints, and progress visualization.

---

## Features

### Dashboard

- Category-based productivity overview
- Quick statistics and progress tracking
- Category progress visualization
- Long-term roadmap preview

### Category Management

- Create custom categories
- Edit category name and icon
- Kanban categories
- Checklist categories

### Task Management

- Create, edit, and delete tasks
- To Do / In Progress / Completed workflow
- Estimated duration tracking
- Due dates and reminder timing
- Task descriptions and notes
- Progress tracking through subtasks

### Task Linking

- Link tasks across categories
- Resource attachment support
- External links for:
  - GitHub
  - YouTube
  - Google Drive
  - Documentation
  - Learning resources

### Checklist Categories

- Lightweight checklist tracking
- Simple completion workflow
- Ideal for recurring or personal lists

### Roadmap System

- Long-term goal tracking
- Custom checkpoints
- Progress visualization
- Task-linked milestone tracking

### Notifications

- Due date reminders
- Overdue task alerts
- In-app notification center

### Archive System

- Automatic task archiving
- Archive browsing and restoration
- Permanent deletion options

### Data Management

- JSON export/import
- PDF report export
- Local backups

---

## Tech Stack

- Flutter
- Dart
- SQLite (sqflite)
- Provider
- Flutter Local Notifications
- PDF Generation
- File Import / Export
- URL Launcher

---

## Architecture

Trackeon follows a local-first architecture.

All data is stored locally on the device, allowing the app to function completely offline without requiring a backend server.

Main modules include:

- Dashboard
- Categories
- Task Management
- Roadmap Tracking
- Notifications
- Archive System
- Data Import/Export

---

## Development Approach

This project was built primarily through a **vibe-coding workflow**.

The original productivity system began as a browser-based application and later evolved into a Flutter mobile app. Development focused heavily on iterative prompting, testing, debugging, and feature refinement using AI-assisted tools.

The goal was both to create a practical productivity tool and to explore how modern AI workflows can accelerate end-to-end application development.

---

## Use Cases

Trackeon can be used for:

- Learning plans
- Personal projects
- Academic work
- Skill roadmaps
- Resource management
- Daily productivity tracking
- Long-term goal planning

---

## Project Status

Personal project currently used as a daily productivity system.

The project also serves as an experiment in AI-driven software development and vibe-coding workflows.

---

## License

This project is intended for personal and portfolio use.
