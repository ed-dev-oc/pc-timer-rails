import { application } from "./application";

import HelloController from "./hello_controller";
import ChartController from "./chart_controller";
import CoinSlotSessionTimerController from "./coin_slot_session_timer_controller";
import SessionTimerController from "./session_timer_controller";

application.register("hello", HelloController);
application.register("chart", ChartController);
application.register("coin-slot-session-timer", CoinSlotSessionTimerController);
application.register("session-timer", SessionTimerController);
