import sys
import numpy as np
#import matplotlib.pyplot as plt

#read the data file
dataFilename = "../mocap_test/labelled_data.txt"
if(len(sys.argv) > 6):
  dataFilename = sys.argv[6]

txtfile = open(dataFilename)
lines = txtfile.read().split("\n")
#remove the field names
fieldnames = lines.pop(0).strip().split("\t")

#remove fieldnames of frame, time and valid
fieldnames.pop(0)
fieldnames.pop(0)
fieldnames.pop()

rot_fields = [i for i, j in enumerate(fieldnames) if j.find('Rotation') != -1]
pos_fields = [i for i, j in enumerate(fieldnames) if j.find('Position') != -1]

pos_data = []
rot_data = []
pos_labels = []
rot_labels = []

POS_LABEL_DIM = 3
ROT_LABEL_DIM = 4

row_count = 0
for line in lines:
  if row_count > 40:
    break
  fields = line.strip().split("\t")
  if(len(fields) != len(fieldnames) + 3):
    continue
  #take out frame num
  fields.pop(0)
  #take out time
  fields.pop(0)
  #now take out the last column - it is the valid indicator
  fields.pop()

  #this is where to remove any fields such as rotation or position
  #doing it the slow way
  
  #position data
  tmp = []
  for idx in pos_fields:
    tmp.append(fields[idx])#this includes the label
  pos_data.append(tmp[:len(tmp) - POS_LABEL_DIM])
  pos_labels.append(tmp[len(tmp) - POS_LABEL_DIM:])
  
  #Rotation Data 
  tmp = []
  for idx in rot_fields:
    tmp.append(fields[idx])#this includes the label
  rot_data.append(tmp[:len(tmp) - ROT_LABEL_DIM])
  rot_labels.append(tmp[len(tmp) - ROT_LABEL_DIM:])
  
N = len(pos_data) #number of training examples - around 4K
D = len(pos_data[0]) #dimensionality - around 6*3 = 18
K = 1 #there are no classes as this is regression
X = np.zeros((N*K,D))
y = np.zeros((N*K,POS_LABEL_DIM))

#copy data into X
outfile = open("positions_only_mocap_data.txt", 'w');
for row in range(N):
  for column in range(D):
    X[row, column] = float(pos_data[row][column]) #Slow way
    outfile.write("%s\t" % pos_data[row][column]);
  outfile.write("\n")
outfile.close();

outfile = open("positions_only_mocap_labels.txt", 'w');
#copy labels into Y
for row in range(N):
  for column in range(POS_LABEL_DIM):
    y[row, column] = float(pos_labels[row][column]) #Slow way
    outfile.write("%s\t" % pos_labels[row][column]);
  outfile.write("\n")
outfile.close();

  
# ######################################################################

 
N = len(rot_data) #number of training examples - around 4K
D = len(rot_data[0]) #dimensionality - around 6*4 = 24
K = 1 #there are no classes as this is regression
X = np.zeros((N*K,D))
y = np.zeros((N*K,ROT_LABEL_DIM))

outfile = open("rotations_only_mocap_data.txt", 'w');
#copy rot_data into X
for row in range(N):
  for column in range(D):
    X[row, column] = float(rot_data[row][column]) #Slow way
    outfile.write("%s\t" % rot_data[row][column]);
  outfile.write("\n")
outfile.close();
  
outfile = open("rotations_only_mocap_data_labels.txt", 'w');
#copy labels into Y
for row in range(N):
  for column in range(ROT_LABEL_DIM):
    y[row, column] = float(rot_labels[row][column]) #Slow way
    outfile.write("%s\t" % rot_labels[row][column]);
  outfile.write("\n")
outfile.close();
    


