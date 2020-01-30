# Script to fill in the particpants table in the rlnoise db 

'''
	Script to fill in the particpants_blocks table in the rlnoise_db 
 	The columns of the table: 

 	participant_id      = Column(BigInteger, nullable=False)
 	participant_mat_id  = Column(SmallInteger, nullable=False) 
 	block_number        = Column(SmallInteger, nullable=False)
    block_type          = Column(VARCHAR(length=100), nullable=False)
	reward_1            = Column(VARCHAR(length=100), nullable=False)      
	reward_2            = Column(VARCHAR(length=100), nullable=False)
	th_reward_1         = Column(VARCHAR(length=100), nullable=False)
	th_reward_2         = Column(VARCHAR(length=100), nullable=False)
	position            = Column(VARCHAR(length=100), nullable=False)
	reward_left         = Column(VARCHAR(length=100), nullable=False)
	reward_right        = Column(VARCHAR(length=100), nullable=False)

'''

# Connect to the DB 
import os 
import numpy as np 
import sqlalchemy as db
import random 
import pickle as pkl
import pandas as pd
from scipy.io import loadmat


# Establish the connection with the DB: 
engine     = db.create_engine('mysql://root:pwd@localhost/rlnoise_db')
metadata   = db.MetaData()
connection = engine.connect()

# print the tables names present in the DB: 
engine.table_names()
# Specify the table you want to insert the data into: 
table = db.Table('game_blocks', metadata, autoload=True, autoload_with=engine)
#Inserting many records at ones
query       = db.insert(table) 

path        = os.path.join("/Users/vasilisaskvortsova/Documents/TASKVOL_ONLINE/task/prerequisites/expe_matlab/Data/")
os.chdir(path)

nbOfBlocks       = 6 # 2 training blocks and 4 test blocks 
n_game           = 30 
game_ids         = np.arange(1,n_game+1) 


for i_d in game_ids:
	
	# correct for the 0 before the subj number 
	if i_d < 10: 
		gamepath  = os.path.join(path,('RLVARONLINE_S0{0}_expe.mat'.format(i_d))) 
	else:
		gamepath  = os.path.join(path,('RLVARONLINE_S{0}_expe.mat'.format(i_d))) 

	try: 
		fulldata = loadmat(gamepath)
		print('Data are taken from game {0}'.format(i_d))
	except:
		print("Unable to load the file: {0}".format(gamepath))

	for i_blck in np.arange(nbOfBlocks): 

		# Loop through the blocks: the 1st 2 blocks are the training blocks: 
		info                       = dict()
		info['game_id']            = i_d
		info['block_number']       = i_blck+1

		if i_blck+1 < 3:
			info['block_type'] = 'training'

			info['maxreward']     = 0.0
			info['chance']        = 0.0
			

		else: 
			info['block_type'] = 'testing'

			info['maxreward']     = fulldata['expe'][0][i_blck][10][0][0] 
			info['chance']        = fulldata['expe'][0][i_blck][11][0][0] 
			
		info['block_feedback'] = fulldata['expe'][0][i_blck][0][0][0][8][0][0]
		info['reward_1']       = fulldata['expe'][0][i_blck][3][0]
		info['reward_2']       = fulldata['expe'][0][i_blck][3][1]
		info['position']       = fulldata['expe'][0][i_blck][4][0] 
		info['th_reward_1']    = fulldata['expe'][0][i_blck][2][0]
		info['th_reward_2']    = fulldata['expe'][0][i_blck][2][1]
		info['reward_left']    = info['reward_1']*(info['position']==1) + info['reward_2']*(info['position']==2) # when position == 1 take reward 1 else take reward 2 
		info['reward_right']   = info['reward_1']*(info['position']==2) + info['reward_2']*(info['position']==1)
 


		values_list = [info]
		
		ResultProxy = connection.execute(query,values_list)

# EXAMPLES: To create an empty table in the DB: 
# emp = db.Table('TABLENAME', metadata, db.Column('COLNAME', db.Integer()), db.Column('COLNAME', db.String(255), nullable=False),
# 	db.Column('COLNAME', db.Float(), default=100.0),
# 	db.Column('COLNAME', db.Boolean(), default=True))


# To get the data from the table:  
# results    = connection.execute(db.select([table])).fetchall()
# df         = pd.DataFrame(results)
# df.columns = results[0].keys()
# print(df.head(4))

