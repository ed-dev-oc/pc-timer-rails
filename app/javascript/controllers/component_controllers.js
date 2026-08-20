import { application } from "./application"

import CountDownController from "../../components/shared/session_timer/count_down_component_controller"
application.register("shared--session-timer--count-down", CountDownController)

import ProgressBarController from "../../components/shared/session_timer/progress_bar_component_controller"
application.register("shared--session-timer--progress-bar", ProgressBarController)

import AlarmController from "../../components/shared/session_timer/alarm_component_controller"
application.register("shared--session-timer--alarm", AlarmController)
