# checks if file passed as first arg has changed. if so, calls generator
# usage: python monitor.py filename.txt
import os
import time
import sys
import generate

class monitor(object):
    def __init__(self, filename):
        self.monitor_file = filename
        self._cached_tstamp=os.stat(self.monitor_file).st_mtime
        self.print_file()

    def changedQ(self):
        new_mod_time = os.stat(self.monitor_file).st_mtime
        if not new_mod_time == self._cached_tstamp:
            self._cached_tstamp = new_mod_time
            return True
        return False
    
    def print_file(self):
        f1 = open(self.monitor_file, "r")
        print(f1.read())
        f1.close()


def main(): 
    #filename = sys.argv[1]
    in_csv_filename = "in.csv"
    out_csv_filename = "out.csv"
    m = monitor(in_csv_filename) 
    g = generate.g()

    while(True):
        changed = False
        while(not changed):
            time.sleep(1)
            changed = m.changedQ()
        
    # generate a new melody and write to out file
    out_seq = g.generate(self, g.csv_to_seq_proto(in_csv_filename), num_steps=128, temperature=1)
    g.seq_proto_to_csv(out_seq, out_csv_filename)
    


if __name__ == "__main__":
    main()