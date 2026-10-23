"""Prende /sim/run/state e una /slam/map, porta la mappa nel frame del tracciato
con la posa di partenza pubblicata e conta i coni che cadono su un cono vero.
    python3 check_map_frame.py <file tracciato yaml>
"""
import json
import math
import sys
import time

import rclpy
from as_msgs.msg import SlamMap
from rclpy.node import Node
from rclpy.qos import DurabilityPolicy, QoSProfile, ReliabilityPolicy
from std_msgs.msg import String

from as_sim.utils.track_io import load_track

track = load_track(sys.argv[1])
truth = [(c.x, c.y) for c in track.cones]

rclpy.init()
node = Node("check_map_frame")
got = {}
node.create_subscription(String, "/sim/run/state", lambda m: got.__setitem__("state", m), 1)
node.create_subscription(SlamMap, "/slam/map", lambda m: got.__setitem__("map", m),
                         QoSProfile(depth=1, durability=DurabilityPolicy.TRANSIENT_LOCAL,
                                    reliability=ReliabilityPolicy.RELIABLE))
t0 = time.time()
while len(got) < 2 and time.time() - t0 < 15:
    rclpy.spin_once(node, timeout_sec=0.2)

state = json.loads(got["state"].data)
m = got["map"]
x0, y0, yaw0 = state["start"]
print(f"stato: {state['phase']} {state['as_state']} track={state['track']} start={state['start']}")


def matched(points):
    return sum(1 for (x, y) in points
               if min(math.hypot(x - tx, y - ty) for tx, ty in truth) < 0.5)


c, s = math.cos(yaw0), math.sin(yaw0)
in_track = [(x0 + c * x - s * y, y0 + s * x + c * y) for x, y in zip(m.cones_x, m.cones_y)]
raw = list(zip(m.cones_x, m.cones_y))
print(f"coni mappati: {len(raw)}")
print(f"  con la posa di partenza: {matched(in_track)} su un cono vero (<0.5 m)")
print(f"  senza trasformazione:    {matched(raw)} su un cono vero (<0.5 m)")
