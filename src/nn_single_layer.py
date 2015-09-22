import sys
import numpy as np
#import matplotlib.pyplot as plt

#NOTES FROM ROSS - 9/9/15
#NOTE:  W should be 42x7
#NOTE:  Bias should be 1x7
#for linear regression -
#loss = 0.5*sum((scores-targets)^2)
#scores = Wx + b
#dL/dW = dL/dscores * dscores/dW
#dL/dscores = (score - y)
#dscores/dW = X
#so
#dL/dW = (score - y) * X
#you can then update the weights with this gradient

# some hyperparameters
step_size = 1e-4
reg = 0 #1e-4 # regularization strength#read the data file
hidden_layer_size = 21
iteration_count = 1000000
only_positions = True
only_rotations = False

if(len(sys.argv) > 1):
  hidden_layer_size = float(sys.argv[1])
  print "Using hidden layer size %d" % hidden_layer_size

if(len(sys.argv) > 2):
  reg = float(sys.argv[2])
  print "Using reg %f " % (reg)

if(len(sys.argv) > 3):
  iteration_count = int(sys.argv[3])
  print "iterations  %d " % (iteration_count)

if(len(sys.argv) > 4):
  only_positions = bool(sys.argv[4])
  print "only_positions " + str(only_positions)

if(len(sys.argv) > 6):
  only_rotations = bool(sys.argv[4])
  print "only_rotations " + str(only_rotations)

  
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

LABEL_DIM = 7
if(only_positions):
  LABEL_DIM = 3
if(only_rotations):
  LABEL_DIM = 4

data = []
labels = []
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
  if(only_positions):
    tmp = []
    for idx in pos_fields:
      tmp.append(fields[idx])#this includes the label
    data.append(tmp[:len(tmp) - LABEL_DIM])
    labels.append(tmp[len(tmp) - LABEL_DIM:])
  if(only_rotations):
    tmp = []
    for idx in rot_fields:
      tmp.append(fields[idx])#this includes the label
    data.append(tmp[:len(tmp) - LABEL_DIM])
    labels.append(tmp[len(tmp) - LABEL_DIM:])
  else:
    data.append(fields[:len(fields) - LABEL_DIM])
    labels.append(fields[len(fields) - LABEL_DIM:])
  row_count += 1

print "Data:"
print data

N = len(data) #number of training examples - around 4K
D = len(data[0]) #dimensionality - around 42
K = 1 #there are no classes as this is regression
X = np.zeros((N*K,D))
y = np.zeros((N*K,LABEL_DIM))

#copy data into X
for row in range(N):
  for column in range(D):
    X[row, column] = float(data[row][column]) #Slow way
  
#copy labels into Y
for row in range(N):
  for column in range(LABEL_DIM):
    y[row, column] = float(labels[row][column]) #Slow way
  
print "done importing data"
#NOTE: I manually checked parsing... it is correct.

#Train a neural net
# initialize parameters randomly
h = hidden_layer_size # size of hidden layer
W = 0.01 * np.random.randn(D,h)
vW = 0.0
b = np.zeros((1,h))
vB = 0.0
W2 = 0.01 * np.random.randn(h,LABEL_DIM)
vW2 = 0.0
b2 = np.zeros((1,LABEL_DIM))
vB2 =0.0

mu = 0.001

last_loss = 999999999.99
# gradient descent loop
num_examples = X.shape[0]
for i in xrange(iteration_count):

  # evaluate class scores, [N x K]
  hidden_layer = np.maximum(0, np.dot(X,W) + b) #note ReLU activation
  scores = np.dot(hidden_layer, W2) + b2
  
  #compute the L2 loss
  score_diff = np.subtract(scores, y)
  L2_loss = 0.5 * np.sum(np.multiply(score_diff,score_diff))


  data_loss = L2_loss
  reg_loss = 0.5*reg*np.sum(W*W) #this stays the same
  loss = data_loss + reg_loss #this stays the same
  
  #reduce step size if we start getting worse performance
  if loss > last_loss:
    step_size *= 0.99
  
  if i % 100 == 0:
    print "iteration %d h: %d\t mu: %f\treg: %f\tstep_size: %f\tloss %f" % (i, h, mu, reg, step_size, loss)
    last_loss = loss

  # compute the gradient on scores
  dscores = score_diff

  # backpropate the gradient to the parameters
  # first backprop into parameters W2 and b2
  dW2 = np.dot(hidden_layer.T, dscores)
  db2 = np.sum(dscores, axis=0, keepdims=True)
  # next backprop into hidden layer
  dhidden = np.dot(dscores, W2.T)
  # backprop the ReLU non-linearity
  dhidden[hidden_layer <= 0] = 0
  # finally into W,b
  dW = np.dot(X.T, dhidden)
  db = np.sum(dhidden, axis=0, keepdims=True)

  # add regularization gradient contribution
  dW2 += reg * W2
  dW += reg * W
  
  
  #calculate nesterov momentum update
  vW_prev = vW  #back up v
  vW = mu * vW - step_size * dW
  W += -mu * vW_prev + (1 + mu) * vW
  
  vW2_prev = vW2  #back up v
  vW2 = mu * vW2 - step_size * dW2
  W2 += -mu * vW2_prev + (1 + mu) * vW2
  
  vB_prev = vB
  vB = mu * vB - step_size * db
  b += -mu * vB_prev + (1 + mu) * vB
  
  vB2_prev = vB2
  vB2 = mu * vB2 - step_size * db2
  b2 += -mu * vB2_prev + (1 + mu) * vB2

  #old vanilla update
  #W += -step_size * dW
  #b += -step_size * db
  #W2 += -step_size * dW2
  #b2 += -step_size * db2
  
# evaluate training set accuracy
hidden_layer = np.maximum(0, np.dot(X, W) + b)
scores = np.dot(hidden_layer, W2) + b2
score_diff = np.subtract(scores,y)
distances = np.sqrt(np.multiply(score_diff, score_diff))
avg_distance = np.sum(distances)/num_examples
#predicted_class = np.argmax(scores, axis=1)
print 'training accuracy (distance): %.2f meters' % avg_distance
# data units are in meters.. although we mixed in a quaternion
