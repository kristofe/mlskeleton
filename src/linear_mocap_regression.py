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


#read the data file
dataFilename = "../mocap_test/labelled_data.txt"
if(len(sys.argv) > 1):
  dataFilename = sys.argv[1]

txtfile = open(dataFilename)
lines = txtfile.read().split("\n")
#remove the field names
fieldnames = lines.pop(0).strip().split("\t")

#remove fieldnames of frame, time and valid
fieldnames.pop(0)
fieldnames.pop(0)
fieldnames.pop()

data = []
labels = []
for line in lines:
  fields = line.strip().split("\t")
  if(len(fields) != len(fieldnames) + 3):
    continue
  #take out frame num
  fields.pop(0)
  #take out time
  fields.pop(0)
  #now take out the last column - it is the valid indicator
  fields.pop()
  data.append(fields[:len(fields) - 7])
  labels.append(fields[len(fields) - 7:])
  

N = len(data) #number of training examples - around 4K
D = len(data[0]) #dimensionality - around 42
K = 1 #there are no classes as this is regression
LABEL_DIM = 7
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

#Train a Linear Classifier
  
# initialize parameters randomly
W = 0.01 * np.random.randn(D,LABEL_DIM) #This is 42 weights... looks right(?)
b = np.zeros((1,LABEL_DIM)) #Just one bias

# some hyperparameters
step_size = 1e-5
reg = 1e-3 # regularization strength

# gradient descent loop
num_examples = X.shape[0]
for i in xrange(50000):

  # evaluate class scores, [N x K]
  scores = np.dot(X, W) + b
  
  #compute the L2 loss
  score_diff = np.subtract(scores, y)
  L2_loss = 0.5 * np.sum(np.multiply(score_diff,score_diff))


  data_loss = L2_loss
  reg_loss = 0.5*reg*np.sum(W*W) #this stays the same
  loss = data_loss + reg_loss #this stays the same
  if i % 100 == 0:
    print "iteration %d: loss %f" % (i, loss)

  # compute the gradient on scores
  dscores = score_diff

  # backpropate the gradient to the parameters (W,b)
  dW = np.dot(X.T, dscores)
  db = np.sum(dscores, axis=0, keepdims=True)

  dW += reg*W # regularization gradient

  # perform a parameter update
  W += -step_size * dW

# evaluate training set accuracy
scores = np.dot(X, W) + b
score_diff = np.subtract(scores,y)
distances = np.sqrt(np.multiply(score_diff, score_diff))
avg_distance = np.sum(distances)/num_examples
#predicted_class = np.argmax(scores, axis=1)
print 'training accuracy (distance): %.2f meters' % avg_distance
# data units are in meters.. although we mixed in a quaternion
