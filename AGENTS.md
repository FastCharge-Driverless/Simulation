# AGENTS.md — Simulation workspace (+ sibling stack workspace)

There are TWO workspaces on this machine, and a level ≥1 run needs BOTH:
- `Simulation/` (this repo root): ROS 2 Humble colcon workspace holding `as_sim`
  ONLY (plus vendored `common_interfaces`, plus the Unity project). No stack
  nodes, no `ros_tcp_endpoint` — `ros2 pkg prefix ros_tcp_endpoint` fails here.
- Sibling `as_workspace/` (Desktop, `dev` branch, git-submodule monorepo):
  the full autonomy stack (`as_slam`, `as_path_planning`,
  `as_high_level_control`, `as_execution_manager`, `as_msgs`, …) AND
  `ros_tcp_endpoint`. No `as_sim`.

Root `Simulation/` is **not** committed
(no commits, no remote); real history lives in the sub-repos:
`as_sim/` (`feat/visualizer`, ahead of `main`), `FSAE_Visualizer/` (`main`),
`common_interfaces/` (vendored ROS Humble messages, do not edit).

## Layout

- `as_sim/` — the simulator. Python `ament_python` package (`as_sim/as_sim/`,
  entry points in `setup.py`): `sim_vehicle_node`, `sim_sensor_node`,
  `sim_annotator`, `track_generator`, `synthetic_bag_generator`, `as_sim_evaluator`.
- `FSAE_Visualizer/` — Unity project (separate repo). Talks to ROS via
  `ros_tcp_endpoint` + Unity ROS-TCP (`Assets/RosMessages`, `Assets/Scripts`).
  ROS work stays on Linux/Humble; Unity work stays in that dir.
  Exception: the SLAM layer is **not** live ROS — `ConeMapSubscriber` loads a
  static CSV (`x,y,z,color`) from `Assets/StreamingAssets/slam_maps/` and spawns
  all cones at once. Regenerate with `python3 as_sim/scripts/track_to_csv.py
  --all <that dir>`; switch tracks via the `csvFileName` Inspector field.
  `RosSessionLauncher` (opt-in, attach + Play) owns the whole ROS session in
  WSL: `ros_tcp_endpoint` and `ros2 launch as_sim sim.launch.py` (level/track
  are Inspector fields). Kills stale holders first, full sim log at
  `/tmp/as_sim_unity.log`, errors mirrored to the Console. One owner per side:
  it kills hand-started terminals too, so don't mix manual + auto.
  Unity compile errors live in `FSAE_Visualizer/Logs/Editor.log`
  (grep `error CS`) — readable without opening the editor.
- `build/`, `install/`, `log/` — colcon artifacts at workspace root (packages
  sit at root, there is **no** `src/` dir). Never commit them; `as_sim/.gitignore`
  already excludes them plus `*_evaluation_report*`, `benchmark_*`.
  `FSAE_Visualizer/COLCON_IGNORE` exists so colcon doesn't crawl Unity's
  `Library/` (~47k files) — never delete it.
- ROS lives in WSL Ubuntu 22.04, not Windows: build with
  `colcon build --symlink-install --packages-select as_sim` from the workspace
  root (`/mnt/c/...`). WSL user-site needs `packaging>=24` with
  `setuptools<80` (colcon-core 0.21 cap); stale `build/`/`install/` from another
  machine must be wiped (`rm -rf build install log`) or symlink-install fails
  with `File exists`.
- Docs under `as_sim/` reference `/home/lorenzo/.../as_workspace`. Wrong here:
  substitute this root.

## Build / run

```bash
source /opt/ros/humble/setup.bash
colcon build --symlink-install --packages-select as_sim
source install/setup.bash   # run from workspace root, before any ros2 command
```

For level ≥1 / Unity runs, overlay BOTH workspaces (order: Humble, then
as_workspace underlay, then Simulation — packages are disjoint so order barely
matters, but sourcing only Simulation silently degrades: `sim.launch.py`
catches missing stack packages per node and runs sim-only, logging
`[sim.launch] Warning: could not configure …`. If the car never drives at
level 4, check the launch log for those lines first.
```bash
source /opt/ros/humble/setup.bash
source ~/Desktop/as_workspace/install/setup.bash
source ~/Desktop/Simulation/install/setup.bash
```

Levels `0-6` via `ros2 launch as_sim sim.launch.py` (default `level:=4`):
`0` sensor+vehicle only, `1` +SLAM, `2` +planning, `3` open-loop stack,
`4` closed-loop (`auto_drive=false`, HLC drives physics), `5` +CAN plant on
`vcan0`, `6` HIL (real bus `can0`, `can_plant` off, `hal_can` off).
Levels `<4` set `auto_drive=true` (car follows reference line).

```bash
ros2 launch as_sim sim.launch.py level:=2 track:=skidpad rviz:=true eval:=true
bash as_sim/scripts/setup_vcan.sh   # required once before any level 5 run
ros2 launch as_sim sim.launch.py level:=5 track:=skidpad rviz:=true eval:=true
```

Headless judged run (wraps `sim.launch.py`, forces `eval:=true`):

```bash
ros2 launch as_sim benchmark.launch.py track:=autocross_default mission:=autocross \
  physics:=dynamic_limit level:=4 duration:=90.0 report:=/tmp/run.json
# writes /tmp/run.json + /tmp/run_summary.md + /tmp/run_junit.xml
```

CI suite: `bash as_sim/scripts/ci_acceptance.sh [out_dir] [level] [duration] [physics] [tracks...]`
(defaults `temp/ci 4 60.0 dynamic_limit skidpad acceleration autocross_default`).

## Fast verification (no ROS needed)

Pure-Python unit tests use a `sys.path` hack, run from `as_sim/`:

```bash
cd as_sim && python3 -m pytest test/test_bicycle_model.py -q
cd as_sim && python3 -m pytest test/ -q
```

`test/test_acceptance.py` tests the judge itself: every check is exercised both
directions (clean run passes, single-violation run fails only that check).

## Gotchas (all verified in code/comments)

- **Isolate ROS.** Multiple agents share hosts. Always export a free domain:
  `export ROS_DOMAIN_ID=<free> ROS_LOCALHOST_ONLY=1`. Scripts default to 93/97.
  Never kill nodes you did not start.
- **`duration` is simulated seconds.** `benchmark.launch.py` divides the shutdown
  timer by `time_scale`; `vehicle_node` owns `/clock`, every other node runs
  `use_sim_time:=true`. Never mix wall/sim time; bag recording must include `/clock`.
- **`benchmark.launch.py` forwards args explicitly** (`physics`, `mission`,
  `acceptance_file`, `time_scale`, `stage`, ...). Do not rely on global launch-arg
  scoping leaking them into `sim.launch.py`.
- **`/slam/odom` single publisher.** `sim.launch.py` sets
  `publish_slam_odom=false` when the stack runs at level ≥ 1. Re-enabling it puts
  track-frame and map-frame poses on one topic (measured: 14002 msgs where 7001
  sent, teleports up to 143 m).
- **`/slam/map` is latched state** (`TRANSIENT_LOCAL`, depth 1, only on change).
  Never add it to liveness gap checks; liveness is `/pp/trajectory`,
  `/cv/detections/fused`, `/hlc/commands` + each `ASNode`'s `/heartbeat`.
  The evaluator exits non-zero on FAIL — a launch "process has died" from the
  evaluator means verdict FAIL, not infra. Only `STARTUP: nothing has arrived`
  (or a missing report) means INFRA; `ci_acceptance.sh` retries once, then labels INFRA vs FAIL.
- **Track/mission coupling.** Empty `mission` infers from `track`; `track` also
  auto-resolves (`skidpad` + autocross/trackdrive mission → `autocross_default`).
  `mission` selects FS-rules (laps, stop distance), so pass it explicitly in judged runs.
- **`stage:=true` (default)** parks the car behind the start line per DS 1.5
  (0.3 m accel, 15 m skidpad, 6 m autocross/trackdrive). `false` starts on the line.
  Staged starts currently strike cones on some layouts — known open issue, see `docs/GUIDE.md`.
- **Widths:** `vehicle.body_width` (1.40 m) is the single source for collision box
  and judge half-width. `vehicle.track_width` (1.20 m) is axle track — never use it for strikes.
- **Color IDs differ:** CV `/cv/detections` = `0 blue, 4 yellow, 3 orange_small,
  2 orange_big, 255 unknown`; SLAM `/slam/map` = `0 blue, 1 yellow, 3 orange_small,
  4 orange_big`. Do not unify without fixing both ends.
- **Speed units differ:** `/hlc/commands.speed_target` is km/h, `/odom` is m/s.
  Compare via `/sim/speed_target_ms`, not raw.
- **Judge source of truth is `as_sim/config/acceptance.yaml`** (invariants /
  thresholds / regression + per-physics `overrides`). Baseline only rewrites on a
  passing suite. Skidpad/acceleration lap rules (D4.2.1/D5.2.1) are UNVERIFIED —
  no stack counter publishes them, so they are absent, not satisfied. The shipped
  skidpad reference line passes ~0.06 m inside a cone; `track_is_drivable`
  fixture absorbs strikes there instead of blaming the controller.
- Commits in `as_sim` follow Conventional Commits (`feat(sim): …`, `fix(sim): …`).
