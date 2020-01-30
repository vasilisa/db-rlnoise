# Script to fill in the particpants_game table in the rlnoise db 

'''
	Script to fill in the particpants_blocks table in the rlnoise_db 
 	The columns of the table: 

 	participant_id  = Column(BigInteger,   nullable=False)
 	game_id         = Column(SmallInteger, nullable=False) 


'''

# Connect to the DB 
import os 
import numpy as np 
import sqlalchemy as db
import random 
import pickle as pkl
import pandas as pd
from  scipy.io import loadmat


# Establish the connection with the DB: 
engine     = db.create_engine('mysql://root:pwd@localhost/rlnoise_db')
metadata   = db.MetaData()
connection = engine.connect()

# print the tables names present in the DB: 
engine.table_names()
# Specify the table you want to insert the data into: 
table = db.Table('participants_game', metadata, autoload=True, autoload_with=engine)
#Inserting many records at ones
query = db.insert(table) 


# Create mapping between games and the participant IDs
n_participant    = 1000 
participant_ids  = np.arange(1,n_participant+1) # assume 1000 participants, each particpant is assigned to a game_id 
n_game           = 30 
game_ids         = np.arange(1,n_game+1) 

k  = np.int(n_participant/n_game)
m  = np.remainder(n_participant,n_game)

idx   = np.asarray(np.repeat(game_ids,k))
idx   = np.append(idx,game_ids[:m],axis = 0)
random.shuffle(idx)


for i_d in np.arange(n_participant): 

	info = dict()
	info['participant_id'] = participant_ids[i_d]
	info['game_id']        = idx[i_d]

	values_list = [info]
	ResultProxy = connection.execute(query,values_list)


# EXAMPLES: To create an empty table in the DB: 
# emp = db.Table('TABLENAME', metadata, db.Column('COLNAME', db.Integer()), db.Column('COLNAME', db.String(255), nullable=False),
# 	db.Column('COLNAME', db.Float(), default=100.0),
# 	db.Column('COLNAME', db.Boolean(), default=True))


# To get the data from the table:  
results    = connection.execute(db.select([table])).fetchall()
df         = pd.DataFrame(results)
df.columns = results[0].keys()
print(df.head(4))

