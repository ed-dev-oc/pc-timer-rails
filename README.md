# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Configuration

### Shutdown Wait Time (`pc_shutdown_wait_time`)

*Type*: **duration**

The amount of time (in seconds) the system will wait before shutting down a PC after a shutdown request is received. The default value is **300 seconds** (5 minutes). This setting can be adjusted via the **Admin Settings UI** under *Advanced* settings.

Changing this value updates the behavior of `Pc#schedule_shutdown`, which now reads the configured duration and schedules `Pcs::ShutdownScheduleJob` accordingly.

## TODO
- Add code for sending command to ESP enable and disable coin insert.