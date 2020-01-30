'''
 Script to fill in the particpants_blocks table in the rlnoise_db 
 The columns of the table: 
 	participant_id           = Column(BigInteger, nullable=False)
    blocks_numbers           = Column(VARCHAR(length=100), nullable=False)
    blocks_feedback          = Column(VARCHAR(length=100), nullable=False)
    training_blocks_feedback = Column(VARCHAR(length=100), nullable=False)
    shape_1                  = Column(VARCHAR(length=100), nullable=False) 
    shape_2                  = Column(VARCHAR(length=100), nullable=False)
    color_1                  = Column(VARCHAR(length=100), nullable=False)
    color_2                  = Column(VARCHAR(length=100), nullable=False)

'''

# Connect to the DB 
import os 
import numpy as np 
import sqlalchemy as db
import random 
import pickle as pkl

from scipy.io import loadmat
import pandas as pd 
# Extract the necessary information from the .mat file 
info = dict()

# Establish the connection with the DB: 
engine     = db.create_engine('mysql://root:pwd@localhost/rlnoise_db')
metadata   = db.MetaData()
connection = engine.connect()
# print the tables names present in the DB: 
engine.table_names()

nbOfBlocks = 6 # 2 training blocks and 4 test blocks 
n_game     = 30 
game_ids   = np.arange(1,n_game+1) 


# Specify the table you want to insert the data into: 
table  = db.Table('games', metadata, autoload=True, autoload_with=engine)
#Inserting many records at ones
query  = db.insert(table) 

path   = os.path.join("/Users/vasilisaskvortsova/Documents/TASKVOL_ONLINE/task/prerequisites/expe_matlab/Data/")
os.chdir(path)

# Fill in the dictionnary to be put in the DB later 

for i_d in game_ids: 

	# correct for the 0 before the subj number 
	if i_d < 10: 
		gamepath  = os.path.join(path,('RLVARONLINE_S0{0}_expe.mat'.format(i_d))) # game_idx
	else:
		gamepath  = os.path.join(path,('RLVARONLINE_S{0}_expe.mat'.format(i_d))) # game_idx

	try: 
		fulldata = loadmat(gamepath)
		print('Data are taken from game {0}'.format(i_d))
	except:
		print("Unable to load the file: {0}".format(gamepath))


	# for pair subjects: start with the PARTIAL feedback == 1, for unpair: with the COMPLETE feedback == 2 
	# the training blocks always start with the PARTIAL feedback  
	if np.mod(i_d,2) == 0: 
		blocks_feedback = np.asarray([1,2,1,2,1,2]) 
	else: 
		blocks_feedback = np.asarray([1,2,2,1,2,1])
	
	for i_blck in np.arange(nbOfBlocks): 

		info                   = dict()
		info['game_id']        = i_d
		info['block_number']   = i_blck+1
		info['block_feedback'] = blocks_feedback[i_blck] 

		if i_blck == 0:  # for training sessions the shapes are the same across all subjects: they might overlap with the main sessions 
			info['symbol_1'] = ('symbol_shape_'+str(0)+'_grate_None_color_'+str(3)+'.png')
			info['symbol_2'] = ('symbol_shape_'+str(2)+'_grate_None_color_'+str(0)+'.png')

		elif i_blck == 1: 
			info['symbol_1'] = ('symbol_shape_'+str(1)+'_grate_None_color_'+str(2)+'.png')
			info['symbol_2'] = ('symbol_shape_'+str(3)+'_grate_None_color_'+str(1)+'.png')
		elif i_blck > 1: 
			info['symbol_1'] = ('symbol_shape_'+str(fulldata['expe'][0][i_blck][5][0][0])+'_grate_None_color_'+str(fulldata['expe'][0][i_blck][6][0][0])+'.png')
			info['symbol_2'] = ('symbol_shape_'+str(fulldata['expe'][0][i_blck][5][1][0])+'_grate_None_color_'+str(fulldata['expe'][0][i_blck][6][1][0])+'.png')

		values_list = [info]
		ResultProxy = connection.execute(query,values_list)




# EXAMPLES: To create an empty table in the DB: 
# emp = db.Table('TABLENAME', metadata, db.Column('COLNAME', db.Integer()), db.Column('COLNAME', db.String(255), nullable=False),
# db.Column('COLNAME', db.Float(), default=100.0),
# db.Column('COLNAME', db.Boolean(), default=True))

# To get the data from the table:  
results    = connection.execute(db.select([table])).fetchall()
df         = pd.DataFrame(results)
df.columns = results[0].keys()
print(df.head(5))

