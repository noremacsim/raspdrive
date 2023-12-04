#!/usr/bin/python3
import time
import os
from watchdog.observers import Observer
from watchdog.events import *

CMD_FLUSH = "sh /root/bin/enable_gadget.sh"

WATCH_PATH = "/mnt/connectedUSB"
ACT_EVENTS = [DirDeletedEvent, DirMovedEvent, FileDeletedEvent, FileModifiedEvent, FileMovedEvent]
ACT_TIME_OUT = 5

class DirtyHandler(FileSystemEventHandler):
    def __init__(self):
        self.reset()

    def on_any_event(self, event):
        if type(event) in ACT_EVENTS:
            self._dirty = True
            self._dirty_time = time.time()

    @property
    def dirty(self):
        return self._dirty

    @property
    def dirty_time(self):
        return self._dirty_time

    def reset(self):
        self._dirty = False
        self._dirty_time = 0
        self._path = None


os.system(CMD_FLUSH)

evh = DirtyHandler()
observer = Observer()
observer.schedule(evh, path=WATCH_PATH, recursive=True)
observer.start()

try:
    while True:
        while evh.dirty:
            time_out = time.time() - evh.dirty_time

            if time_out >= ACT_TIME_OUT:
                os.system(CMD_FLUSH)
                time.sleep(1)
                evh.reset()
            time.sleep(5)
        time.sleep(2)

except KeyboardInterrupt:
    observer.stop()

observer.join()