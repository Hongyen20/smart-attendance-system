# AttendGo — Smart Attendance Management System

**AttendGo** is a smart attendance management system built to help businesses manage employees, work schedules, attendance records, and employee requests through a centralized platform.

The system supports mobile attendance check-in/check-out with multiple verification mechanisms, including public IPv4 address validation, GPS geofencing, and facial recognition. Its **Multi-Tenant architecture** allows multiple businesses to share the same platform while keeping their data logically separated.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [System Architecture](#system-architecture)
- [Attendance Verification](#attendance-verification)
- [User Roles](#user-roles)
- [Deployment](#deployment)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Testing](#testing)
- [Limitations](#limitations)
- [Future Improvements](#future-improvements)
- [Author](#author)

## Overview

Traditional attendance management can involve manual processes and may not adequately verify an employee's identity or attendance location.

AttendGo addresses these challenges by combining attendance verification, employee management, work scheduling, and reporting in one application.

The project focuses on:

- Improving attendance reliability through multiple verification mechanisms.
- Simplifying employee and work-schedule management.
- Supporting leave, shift-change, and business-trip requests.
- Providing attendance history and reporting capabilities.
- Supporting multiple businesses through a shared platform with tenant-level data isolation.

## Key Features

### 1. Smart Check-in / Check-out

- Employee check-in and check-out through the application.
- Public IPv4 address validation.
- GPS-based location verification.
- Facial recognition using Amazon Rekognition.
- Attendance history tracking.

### 2. Employee Management

- Manage employee accounts and information.
- Organize employees by department.
- Configure and manage work shifts.
- Support fixed and flexible working schedules.

### 3. Employee Requests

- Submit leave requests.
- Request work-schedule changes.
- Submit business-trip requests.
- Allow administrators to review and process requests.

### 4. Attendance Reports

- View attendance records.
- Monitor employee check-in/check-out activity.
- Support attendance statistics and reporting for management.

### 5. Multi-Tenant Architecture

- Multiple businesses use a shared application platform.
- Business data is associated with a `companyId`.
- Backend authorization and tenant-level filtering help prevent unauthorized cross-company data access.
- New businesses can be added without deploying a separate application instance for each tenant.

### 6. Authentication and Authorization

- JWT-based authentication.
- Role-based access control.
- Backend authorization for protected API endpoints.

## Technology Stack

| Component | Technology |
|---|---|
| Frontend | Flutter, Dart |
| Backend | C#, ASP.NET Core Web API |
| Database | MongoDB Atlas |
| Authentication | JSON Web Token (JWT) |
| Facial Recognition | Amazon Rekognition |
| Cloud Infrastructure | AWS EC2, Ubuntu |
| Containerization | Docker |
| Web Server / Reverse Proxy | Nginx |
| HTTPS | SSL/TLS |
| CI/CD | GitHub Actions |

## System Architecture

The system follows a client-server architecture.

```text
+-----------------------------+
|       Flutter Client        |
|     Mobile App / Web        |
+--------------+--------------+
               |
            HTTPS
               |
+--------------v--------------+
|           Nginx             |
|   Web Hosting / Reverse     |
|          Proxy              |
+--------------+--------------+
               |
+--------------v--------------+
|     ASP.NET Core Web API    |
|                             |
| - Authentication / JWT      |
| - Role-based Authorization  |
| - Attendance Management     |
| - Tenant Isolation          |
| - Employee Management       |
| - Request Processing        |
+-------+--------------+------+
        |              |
        v              v
+---------------+  +---------------------+
| MongoDB Atlas |  | Amazon Rekognition  |
| Attendance,   |  | Facial Recognition  |
| Employees,    |  |                     |
| Shifts, etc.  |  +---------------------+
+---------------+
```

The backend processes client requests, enforces authentication and authorization, applies tenant-level data filtering, and communicates with the database and external facial-recognition service.

## Attendance Verification

AttendGo combines three verification mechanisms to improve the reliability of attendance records.

| Verification | Purpose |
|---|---|
| Public IPv4 validation | Checks whether the request originates from an allowed public IP address. |
| GPS geofencing | Checks whether the employee's reported location is within the configured attendance area. |
| Facial recognition | Uses Amazon Rekognition to verify the employee's face against the configured recognition workflow. |

These mechanisms serve different purposes and are combined as part of the attendance workflow.

**Note:** Public IP addresses and GPS coordinates have practical limitations. IP addresses may change, and GPS accuracy can decrease indoors or in areas with weak satellite signals.

## User Roles

### SuperAdmin

- Manage businesses on the platform.
- Manage administrator accounts.

### Admin

- Manage employees, departments, and work shifts.
- Configure attendance rules, including IP and GPS settings.
- Review employee requests.
- View attendance records and reports.

### Employee

- Check in and check out.
- View personal attendance history.
- Submit leave, shift-change, and business-trip requests.

## Deployment

The application is deployed using cloud infrastructure and containerized backend services.

| Component | Deployment |
|---|---|
| Cloud server | AWS EC2 |
| Operating system | Ubuntu 24.04 |
| Backend | ASP.NET Core running in Docker |
| Web frontend | Flutter Web served through Nginx |
| Database | MongoDB Atlas |
| Domain and HTTPS | `attendgo.site` |
| CI/CD | GitHub Actions |

GitHub Actions automates the build and deployment workflow to help streamline application updates.

> The deployment configuration may differ between environments. Refer to the actual repository configuration before reproducing the deployment.

## Getting Started

The following steps provide a general setup workflow. Exact commands and configuration depend on the repository structure.

### Prerequisites

- Flutter SDK
- Dart SDK compatible with the Flutter version used by the project
- .NET SDK compatible with the backend target framework
- A MongoDB database, such as MongoDB Atlas
- AWS credentials and service permissions if using Amazon Rekognition
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/Hongyen20/smart-attendance-system.git
cd smart-attendance-system
```

### 2. Configure the Backend

Navigate to the backend directory and restore the dependencies.

```bash
cd backend
dotnet restore
```

Configure the required environment variables and application settings before starting the API.

Run the backend:

```bash
dotnet run
```

### 3. Configure the Frontend

Navigate to the Flutter project directory.

```bash
cd frontend
flutter pub get
```

Update the API base URL to point to your backend environment, then run the application using the appropriate Flutter target.

For example:

```bash
flutter run
```

### 4. Configure External Services

Before using the complete attendance workflow, configure:

- MongoDB connection settings.
- JWT authentication settings.
- Allowed public IP addresses and GPS attendance rules.
- Amazon Rekognition credentials and required AWS permissions.
- Frontend API endpoint and HTTPS settings where applicable.

**Important:** The commands and directory names above are templates. Replace the placeholders with the actual paths and configuration used in your repository.

## Environment Configuration

Store environment-specific configuration outside source code whenever possible.

Typical configuration values may include:

```text
ASPNETCORE_ENVIRONMENT
ConnectionStrings__MongoDB
Jwt__SecretKey
AWS_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

The exact variable names must match the application's implementation.

**Security recommendations:**

- Never commit passwords, JWT signing secrets, database credentials, or AWS access keys.
- Use environment variables, local secret configuration, or a secure secrets manager.
- Apply least-privilege permissions to AWS identities.
- Keep production configuration separate from development configuration.
- Add sensitive local configuration files to `.gitignore`.

## Testing

The system should be evaluated against the following scenarios:

- Attendance requests from allowed and disallowed public IP addresses.
- GPS coordinates inside and outside the configured attendance radius.
- Registered and unregistered faces.
- Repeated check-in/check-out requests and different network conditions.
- Authentication and authorization for different user roles.
- Data isolation between different companies.
- API response time and application stability.

Actual accuracy, response-time measurements, and test results should be documented only when supported by recorded test evidence.

## Limitations

- Public IPv4 addresses may change depending on the network or ISP configuration.
- GPS accuracy can be affected by indoor environments and weak signals.
- Facial recognition depends on the availability, configuration, and cost of the external service.
- Integration with advanced HR, payroll, and enterprise systems is outside the current scope.

## Future Improvements

Potential improvements include:

- More comprehensive automated testing and performance benchmarking.
- Enhanced attendance analytics and reporting.
- Additional integrations with HR and payroll systems.
- Improved monitoring, logging, and production observability.
- Further enhancements to tenant isolation and security controls.

## Author

**Nguyen Thi Hong Yen**

Graduation Project: *Smart Attendance Management System on Mobile Platforms*

Year: 2026

---

*AttendGo is an academic software project focused on smart attendance verification, employee management, and multi-tenant application architecture.*