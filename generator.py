# checks if file passed as first arg has changed. if so, calls generator
# usage: python monitor.py 
import os
import time
import sys
# import magenta
# import note_seq
# import tensorflow
# from magenta.models.melody_rnn import melody_rnn_sequence_generator
# from magenta.models.shared import sequence_generator_bundle
# from note_seq.protobuf import generator_pb2
# from note_seq.protobuf import music_pb2
import py_midicsv as pm


class g(object):
    def __init__(self):
        # Initialize the model.
        print("Initializing Melody RNN...")
        bundle = sequence_generator_bundle.read_bundle_file('basic_rnn.mag')
        generator_map = melody_rnn_sequence_generator.get_generator_map()
        self.melody_rnn = generator_map['basic_rnn'](checkpoint=None, bundle=bundle)
        self.melody_rnn.initialize()

        print('🎉 Done initializing model!')

    def generate(self, input_sequence, tempo, num_steps=128, temperature=1): # requires input sequence in seq_proto format
        # Set the start time to begin on the next step after the last note ends.
        last_end_time = (max(n.end_time for n in input_sequence.notes)
                        if input_sequence.notes else 0)
        qpm = tempo 
        seconds_per_step = 60.0 / qpm / self.melody_rnn.steps_per_quarter
        total_seconds = num_steps * seconds_per_step

        generator_options = generator_pb2.GeneratorOptions()
        generator_options.args['temperature'].float_value = temperature
        generate_section = generator_options.generate_sections.add(
        start_time=last_end_time + seconds_per_step,
        end_time=total_seconds)

        # Ask the model to continue the sequence.
        sequence = self.melody_rnn.generate(input_sequence, generator_options)

        generated_notes = [n for n in sequence.notes if n.start_time >= generate_section.start_time]
        
        # Create a new sequence with only the generated notes
        generated_section_sequence = music_pb2.NoteSequence()
        generated_section_sequence.notes.extend(generated_notes)

        return generated_notes

    def seq_proto_to_csv(self, seq, out_csv_filename): # input is in seq_proto format, returns midi
        note_seq.sequence_proto_to_midi_file(seq, 'output.mid')
        
        csv_string = pm.midi_to_csv("output.mid")
        with open(out_csv_filename, "w") as f:
            f.writelines(csv_string)

    def csv_to_seq_proto(self, in_csv_filename): # input is in seq_proto format, returns midi
        str1 = ""
        with open(in_csv_filename, "r") as f:
            str1 = f.readline()
        measures, tempo = self.parse_comment(str1)

        midi_object = pm.csv_to_midi(in_csv_filename) 
        with open("output.mid", "wb") as output_file:
            midi_writer = pm.FileWriter(output_file)
            midi_writer.write(midi_object)

        ns = note_seq.midi_file_to_sequence_proto("output.mid")
        
        return ns, measures, tempo
    
    def parse_comment(self, str1):
        # remove hashtag
        str1 = str1[1:]

        # grab until space for num measures
        m_str = ""
        for c in str1:
            if not c == ' ':
                m_str += c
                str1 = str1[1:]
            else: # found a space
                str1 = str1[1:] 
                break
        m_num = int(m_str)
        
        # rest is tempo info
        t_num = int(str1)

        return m_num, t_num
    


class monitor(object):
    def __init__(self, filename):
        self.monitor_file = filename
        self._cached_tstamp=os.stat(self.monitor_file).st_mtime
        #self.print_file()

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
    g = g()

    while(True):
        changed = False
        while(not changed):
            time.sleep(1)
            changed = m.changedQ()
        
        # generate a new melody and write to out file
        in_seq, num_measures, tempo = g.csv_to_seq_proto(in_csv_filename)
        print("measures: {}\t tempo: {}".format(num_measures, tempo))
        # still not sure how to use num_measures to calc num_steps TO DO add support for this
        out_seq = g.generate(in_seq, tempo, num_steps=128, temperature=1)
        g.seq_proto_to_csv(out_seq, out_csv_filename)
    

if __name__ == "__main__":
    main()
