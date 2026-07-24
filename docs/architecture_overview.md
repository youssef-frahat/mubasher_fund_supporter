# Architecture Overview

## Frontend
- Flutter latest stable
- Material 3
- Riverpod for state management
- GoRouter for navigation
- Feature-first folder structure

## Backend
- Supabase for auth, database, storage, and realtime
- PostgreSQL as the canonical data store
- Row Level Security for tenant-aware access
- Edge functions for orchestration and AI workflows

## Security
- JWT auth with role-based access control
- Encryption at rest and in transit
- Secure file uploads and validation
- Audit logs and rate limiting

## AI Layer
- Recommendation engine
- OCR and document validation pipeline
- RAG knowledge base
- Market insight generation

## DevOps
- Dockerized services
- CI/CD pipeline via GitHub Actions
- Monitoring and backup strategy
- Disaster recovery planning
